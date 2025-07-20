from subprocess import Popen, PIPE
from picamera2 import Picamera2
import os, sys
import subprocess
import time
import threading
import matplotlib.pyplot as plt
import numpy as np
from collections import deque
from IPython.display import display


#resources file for EDL jupyter notebooks
#2023

# defines an asynchronous stream capture of images
class PiVideoStream:
    def __init__(self, resolution=(640, 480), rgb=False):
        self.picam2 = Picamera2()
        config = self.picam2.create_preview_configuration(main={"size": resolution, "format": "RGB888"})
        self.picam2.configure(config)
        self.picam2.set_controls({"AwbMode": 1})  # Basic AWB mode

        
        self.rgb = rgb
        self.running = False
        self.frame = None
        self.lock = threading.Lock()

    def start(self):
        self.picam2.start()
        time.sleep(2.0) # wait for cam to start
        self.running = True
        self.thread = threading.Thread(target=self.update_frame, daemon=True)
        self.thread.start()

    def update_frame(self):
        while self.running:
            frame = self.picam2.capture_array()
            with self.lock:
                self.frame = frame

    def read(self):
        with self.lock:
            if self.frame is not None:
                # images returned are BRG by default for easier compatibility with opencv
                return self.frame[:, :, ::-1] if self.rgb else self.frame
            return None

    def stop(self):
        self.running = False
        self.thread.join()
        self.picam2.stop() 
        self.picam2.close()

# LiveGraphing class for real-time data visualization.
class LiveGraphing:
    """
    Live graphing class for real-time data visualization.
    Follows PiVideoStream threading pattern for high performance.
    
    Auto-detects single plot (signal only) vs dual plot (signal + output) based on usage.
    Perfect for control systems, sensor monitoring, or any real-time data visualization.
    
    Examples:
        # Temperature monitoring (single plot)
        temp_graph = LiveGraphing()
        temp_graph.start()
        temp_graph.add_data_point(temperature_celsius)
        
        # Control system (dual plot)
        control_graph = LiveGraphing()
        control_graph.start()
        control_graph.add_data_point(error_value, control_response)
        
        # Light sensor with validity
        light_graph = LiveGraphing()
        light_graph.start()
        light_graph.add_data_point(light_level, led_power, valid=sensor_working)
    """
    
    def __init__(self, max_points=500, display_update_seconds=2.0,
                    signal_label="Signal", output_label="Output", title="Live Data"):
        """
        Initialize LiveGraphing for real-time data visualization.
        
        Args:
            max_points (int): Maximum data points to store
            display_update_seconds (float): How often to update display
            signal_label (str): Label for main signal/measurement
            output_label (str): Label for output/response (if used)
            title (str): Main title for the graph
        """
        self.max_points = max_points
        self.display_interval = display_update_seconds
        self.signal_label = signal_label
        self.output_label = output_label
        self.title = title
        
        # Thread-safe data storage
        self.times = deque(maxlen=max_points)
        self.signals = deque(maxlen=max_points)
        self.outputs = deque(maxlen=max_points)
        self.valid_flags = deque(maxlen=max_points)
        self.lock = threading.Lock()
        
        # Auto-detection for plot type
        self.has_output_data = False
        self.dual_mode = False
        
        # Threading control
        self.running = False
        self.thread = None
        self.start_time = None
        
        # Display objects
        self.display_handle = None
        self.figure = None
        self._display_initialized = False
        
        # Performance tracking
        self.add_data_times = []
        self.display_count = 0
        
    def start(self):
        """Start background display thread."""
        if self.running:
            return
            
        print(f"Starting LiveGraphing (updates every {self.display_interval}s)...")
        self.running = True
        self.thread = threading.Thread(target=self._display_loop, daemon=True)
        self.thread.start()
        
    def stop(self):
        """Stop background thread."""
        if not self.running:
            return
            
        #print("Stopping LiveGraphing thread...")
        self.running = False
        if self.thread and self.thread.is_alive():
            self.thread.join(timeout=2.0)
        #print("LiveGraphing stopped.")
        
    def add_data_point(self, signal, output=None, valid=True):
        """
        Add data point with auto-detection of single vs dual plot mode.
        
        Args:
            signal: Main measurement/sensor value
            output: Optional control response/output value
            valid: Whether this data point is valid (default True)
            
        Examples:
            # Single plot mode
            graph.add_data_point(temperature)
            graph.add_data_point(light_level, valid=sensor_ok)
            
            # Dual plot mode  
            graph.add_data_point(error, control_signal)
            graph.add_data_point(distance, motor_speed, valid=sensor_working)
        """
        start_time = time.perf_counter()
        
        current_time = time.time()
        if self.start_time is None:
            self.start_time = current_time
        
        relative_time = current_time - self.start_time
        
        # Auto-detect dual mode
        if output is not None and not self.has_output_data:
            self.has_output_data = True
            self.dual_mode = True
            #print(f"LiveGraphing: Detected output data - switching to dual plot mode")
        
        # Thread-safe data storage
        with self.lock:
            self.times.append(relative_time)
            self.signals.append(signal)
            self.outputs.append(output if output is not None else 0)
            self.valid_flags.append(valid)
        
        # Track performance
        add_time = (time.perf_counter() - start_time) * 1000
        self.add_data_times.append(add_time)
        
    def _display_loop(self):
        """Background thread loop for display updates."""
        while self.running:
            try:
                if not self._display_initialized:
                    self._initialize_display()
                    
                self._update_display()
                
                time.sleep(self.display_interval)
                
            except Exception as e:
                #print(f"LiveGraphing display error: {e}")
                break
                
    def _initialize_display(self):
        """Initialize display once in background thread."""
        plt.ioff()
        
        # Always create dual plot structure, hide second if not needed
        self.figure, (self.ax1, self.ax2) = plt.subplots(2, 1, figsize=(7, 4))
        self.figure.suptitle(f'{self.title} (Updates every {self.display_interval}s)', fontsize=11)
        
        # Setup signal plot
        self.ax1.set_title(self.signal_label, fontsize=10)
        self.ax1.set_ylabel('Value', fontsize=9)
        self.ax1.grid(True, alpha=0.3)
        
        # Setup output plot (may be hidden)
        self.ax2.set_title(self.output_label, fontsize=10)
        self.ax2.set_xlabel('Time (seconds)', fontsize=9)
        self.ax2.set_ylabel('Value', fontsize=9)
        self.ax2.grid(True, alpha=0.3)
        
        # Initially hide second plot if no output data
        if not self.dual_mode:
            self.ax2.set_visible(False)
        
        plt.tight_layout()
        
        self.display_handle = display(self.figure, display_id=True)
        self._display_initialized = True
        
        mode = "dual plot" if self.dual_mode else "single plot"
        #print(f"LiveGraphing display initialized ({mode} mode).")
        
    def _update_display(self):
        """Update display in background thread."""
        # Quickly copy data
        with self.lock:
            if not self.times:
                return
            times_copy = list(self.times)
            signals_copy = list(self.signals)
            outputs_copy = list(self.outputs)
            valid_copy = list(self.valid_flags)
            dual_mode_copy = self.dual_mode
        
        # Check if we need to switch to dual mode
        if dual_mode_copy and not self.ax2.get_visible():
            self.ax2.set_visible(True)
            plt.tight_layout()
        
        # Clear and redraw
        self.ax1.clear()
        if dual_mode_copy:
            self.ax2.clear()
        
        # Reconfigure signal plot
        current_time = time.strftime("%H:%M:%S")
        self.ax1.set_title(f'{self.signal_label} (Updated: {current_time})', fontsize=10)
        self.ax1.set_ylabel('Value', fontsize=9)
        self.ax1.grid(True, alpha=0.3)
        
        # Configure output plot if in dual mode
        if dual_mode_copy:
            self.ax2.set_title(f'{self.output_label} ({len(times_copy)} points)', fontsize=10)
            self.ax2.set_xlabel('Time (seconds)', fontsize=9)
            self.ax2.set_ylabel('Value', fontsize=9)
            self.ax2.grid(True, alpha=0.3)
        else:
            # Single mode - put x-label on signal plot
            self.ax1.set_xlabel('Time (seconds)', fontsize=9)
        
        # Plot data
        times_array = np.array(times_copy)
        signals_array = np.array(signals_copy)
        outputs_array = np.array(outputs_copy)
        valid_array = np.array(valid_copy)
        
        # Plot valid signal data
        valid_mask = valid_array
        valid_times = times_array[valid_mask]
        valid_signals = signals_array[valid_mask]
        
        if len(valid_times) > 0:
            self.ax1.plot(valid_times, valid_signals, 'b.:', linewidth=2, alpha=0.8, label='Valid Data')
            self.ax1.plot(valid_times[-1:], valid_signals[-1:], 'bo', markersize=6)
        
        # Plot invalid signal data
        invalid_times = times_array[~valid_mask]
        invalid_signals = signals_array[~valid_mask]
        if len(invalid_times) > 0:
            self.ax1.plot(invalid_times, invalid_signals, 'rx', markersize=6, alpha=0.8, label='Invalid Data')
        
        # Plot output data if in dual mode
        if dual_mode_copy:
            if len(valid_times) > 0:
                valid_outputs = outputs_array[valid_mask]
                self.ax2.plot(valid_times, valid_outputs, 'g.:', linewidth=2, alpha=0.8, label='Output')
                self.ax2.plot(valid_times[-1:], valid_outputs[-1:], 'go', markersize=6)
            
            if len(invalid_times) > 0:
                invalid_outputs = outputs_array[~valid_mask]
                self.ax2.plot(invalid_times, invalid_outputs, 'rx', markersize=6, alpha=0.8, label='Invalid')
        
        # Auto-scale
        if len(times_array) > 1:
            time_range = times_array[-1] - times_array[0]
            padding = max(time_range * 0.05, 0.1)
            
            self.ax1.set_xlim(times_array[0] - padding, times_array[-1] + padding)
            if dual_mode_copy:
                self.ax2.set_xlim(times_array[0] - padding, times_array[-1] + padding)
        
        # Add legends
        self.ax1.legend(fontsize=8)
        if dual_mode_copy:
            self.ax2.legend(fontsize=8)
        
        # Update display
        if self.display_handle:
            self.display_handle.update(self.figure)
            
        self.display_count += 1
        mode_str = "dual" if dual_mode_copy else "single"
        #print(f"LiveGraphing update #{self.display_count} ({mode_str} mode, t={times_array[-1]:.1f}s)")
        
    def get_performance_stats(self):
        """Get performance statistics."""
        if not self.add_data_times:
            return None
            
        return {
            'total_data_points': len(self.add_data_times),
            'avg_add_data_time_ms': np.mean(self.add_data_times),
            'max_add_data_time_ms': np.max(self.add_data_times),
            'display_updates': self.display_count,
            'mode': 'dual' if self.dual_mode else 'single',
        }
        
    def print_performance_report(self):
        """Print performance analysis."""
        stats = self.get_performance_stats()
        if not stats:
            print("No performance data available")
            return
            
        print(f"\n=== LIVEGRAPHING PERFORMANCE REPORT ===")
        print(f"Graph Mode: {stats['mode']} plot")
        print(f"Data Collection Performance:")
        print(f"  • Total data points: {stats['total_data_points']}")
        print(f"  • Average add_data_point() time: {stats['avg_add_data_time_ms']:.3f}ms")
        print(f"  • Maximum add_data_point() time: {stats['max_add_data_time_ms']:.3f}ms")
        print(f"  • Performance rating: {'✓ EXCELLENT' if stats['avg_add_data_time_ms'] < 1 else '⚠ REVIEW'}")
        print(f"Display Updates: {stats['display_updates']} (background thread)")


# Convenience functions for common use cases
def create_sensor_graph(sensor_name="Sensor", update_seconds=2.0):
    """Create LiveGraphing for single sensor monitoring."""
    return LiveGraphing(
        display_update_seconds=update_seconds,
        signal_label=f"{sensor_name} Reading",
        title=f"{sensor_name} Monitor"
    )

def create_control_graph(system_name="Control System", update_seconds=2.0):
    """Create LiveGraphing for control system visualization."""
    return LiveGraphing(
        display_update_seconds=update_seconds,
        signal_label="Error Signal",
        output_label="Control Output", 
        title=f"{system_name} Performance"
    )

def create_robot_graph(update_seconds=3.0):
    """Create LiveGraphing optimized for robot control loops."""
    return LiveGraphing(
        display_update_seconds=update_seconds,
        signal_label="Measurement",
        output_label="Response",
        title="Robot Control System"
    )



#hides console output for some gopigo methods that like to be very verbose
class HiddenPrints:
    def __enter__(self):
        self._original_stdout = sys.stdout
        sys.stdout = open(os.devnull, 'w')

    def __exit__(self, exc_type, exc_val, exc_tb):
        sys.stdout.close()
        sys.stdout = self._original_stdout

#speak function for the robot
def speak(text, speed=170, voice="mb-us2", pitch=70, gap=40):
    
    """
    Make the robot speak text
    
    Args:
        text (str): Text to speak
        speed (int): Speaking speed (default 170)
        voice (str): Voice to use (default "mb-us2", or "en")
        pitch (int): Pitch of the voice (default 70)
        gap (int): Gap between words in milliseconds (default 40)
    """
    try:
        # Ensure environment is set
        env = os.environ.copy()
        env['XDG_RUNTIME_DIR'] = '/run/user/1001'
        
        # Run espeak-ng with parameters -s 180 -p 70 -g 8 -v mb-us2
        cmd = ['espeak-ng', '-s', str(speed), '-p', str(pitch), '-g', str(gap), '-v', voice, str(text)]
        subprocess.run(cmd, env=env, check=True, stderr=subprocess.DEVNULL)
        
    except subprocess.CalledProcessError:
        print(f"⚠️  Speech failed: Could not say '{text}'")
    except FileNotFoundError:
        print("⚠️  espeak-ng not found")
    except Exception as e:
        print(f"⚠️  Audio error: {e}")

def robot_say(text):
    """Alias for speak()"""
    speak(text)

# IP Announcement Control
def stop_ip_announcements():
    """Stop the robot from announcing its IP address"""
    try:
        result = subprocess.run(['sudo', 'systemctl', 'stop', 'ip_feedback.service'], 
                              capture_output=True, text=True, check=True)
        print("🔇 IP announcements stopped!")
        time.sleep(2)
        speak("IP Announcements Stopped")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to stop IP announcements: {e}")
        return False

def start_ip_announcements():
    """Start the robot announcing its IP address again"""
    try:
        speak("Starting IP Announcements")
        time.sleep(2)
        result = subprocess.run(['sudo', 'systemctl', 'start', 'ip_feedback.service'], 
                              capture_output=True, text=True, check=True)
        print("🔊 IP announcements started!")
        
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to start IP announcements: {e}")
        return False

def quiet_mode():
    if stop_ip_announcements():
        print("Entering quiet mode. Ready to program!")

def ip_status():
    """Check and announce IP announcement status"""
    try:
        result = subprocess.run(['sudo', 'systemctl', 'is-active', 'ip_feedback.service'], 
                              capture_output=True, text=True)
        is_active = result.stdout.strip() == 'active'
        if is_active:
            print("🔊 IP announcements: ON")
            speak("IP announcements are on")
        else:
            print("🔇 IP announcements: OFF")
            speak("IP announcements are off")
        return is_active
    except:
        print("❓ Could not check IP announcement status")
        return None

# Test function
def test_audio():
    """Test robot audio system"""
    stop_ip_announcements()
    print("🤖 Testing robot audio...")
    speak("Hello! Robot audio is working correctly.")
    print("✅ Audio test complete!")
    start_ip_announcements()

#shuts down pi
def shutdown_pi():
    subprocess.Popen(['sudo','shutdown','-h','now'])
    
"""
EDL Robot Take-Home WiFi Setup
Configure home WiFi before leaving lab (headless mode)
"""

import subprocess
import re


def validate_ssid(ssid):
    """Check if SSID is valid"""
    if not ssid or len(ssid.strip()) == 0:
        return False, "SSID cannot be empty"
    if len(ssid) > 32:
        return False, "SSID too long"
    if '"' in ssid or "'" in ssid:
        return False, "Remove quotes from SSID"
    return True, ""

def validate_password(password):
    """Check if password is valid"""
    if len(password) < 8:
        return False, "Password too short (need 8+ chars)"
    if len(password) > 63:
        return False, "Password too long"
    return True, ""

def check_confusing_characters(text, label):
    """Check for commonly confused characters"""
    warnings = []
    
    if 'O' in text and '0' in text:
        warnings.append(f"⚠️  {label} has both O and 0 - double check which is which")
    elif 'O' in text:
        warnings.append(f"{label} has letter O - confirm it's not number 0")
    elif '0' in text:
        warnings.append(f"{label} has number 0 - confirm it's not letter O")
    
    if any(char in text for char in ['I', '1', 'l']):
        confusing_chars = [c for c in ['I', '1', 'l'] if c in text]
        if len(confusing_chars) > 1:
            warnings.append(f"⚠️  {label} has {'/'.join(confusing_chars)} - check: I=letter, 1=number, l=lowercase L")
        elif 'I' in text:
            warnings.append(f"{label} has capital I - confirm it's not number 1 or lowercase l")
        elif '1' in text:
            warnings.append(f"{label} has number 1 - confirm it's not letter I or l")
        elif 'l' in text:
            warnings.append(f"{label} has lowercase l - confirm it's not number 1 or capital I")
    
    if any(char in text for char in ['B', '8']):
        if 'B' in text and '8' in text:
            warnings.append(f"⚠️  {label} has both B and 8 - double check")
        elif 'B' in text:
            warnings.append(f"{label} has letter B - confirm it's not number 8")
        elif '8' in text:
            warnings.append(f"{label} has number 8 - confirm it's not letter B")
    
    if any(char in text for char in ['S', '5']):
        if 'S' in text and '5' in text:
            warnings.append(f"⚠️  {label} has both S and 5 - double check")
    
    # Check for spaces at start/end
    if text != text.strip():
        warnings.append(f"⚠️  {label} has extra spaces - removed automatically")
    
    return warnings

def get_network_info():
    """Get network info with smart validation"""
    print("🏠 HOME WIFI SETUP")
    print("    Check your phone's WiFi settings now")
    print()
    
    # Get SSID
    while True:
        ssid = input("📶 WiFi network name: ").strip()
        
        valid, error = validate_ssid(ssid)
        if not valid:
            print(f"❌ {error}")
            continue
        
        # Check for confusing characters
        warnings = check_confusing_characters(ssid, "Network name")
        for warning in warnings:
            print(warning)
        
        if warnings:
            print(f"You entered: '{ssid}'")
            confirm = input("Correct? (y/n): ").lower().strip()
            if not confirm.startswith('y'):
                print("Try again...\n")
                continue
        
        break
    
    # Get password
    while True:
        password1 = input("🔐 WiFi password: ")
        
        valid, error = validate_password(password1)
        if not valid:
            print(f"❌ {error}")
            continue
        
        # Check for confusing characters
        warnings = check_confusing_characters(password1, "Password")
        if warnings:
            for warning in warnings:
                print(warning)
        
        # Confirm password
        password2 = input("🔐 Confirm password: ")
        
        if password1 != password2:
            print("❌ Passwords don't match")
            continue
        
        break
    
    return ssid, password1

def add_home_wifi(ssid, password):
    """Add WiFi network for home use"""
    try:
        cmd = [
            'sudo', 'nmcli', 'connection', 'add', 
            'type', 'wifi',
            'con-name', f'{ssid}',
            'ssid', ssid,
            'wifi-sec.key-mgmt', 'wpa-psk',
            'wifi-sec.psk', password,
            'connection.autoconnect', 'yes'
        ]
        
        print(f"🔧 DEBUG: Running command...")  # Debug info
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✅ Saved: {ssid}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ nmcli error: {e}")
        print(f"❌ stderr: {e.stderr}")
        print(f"❌ stdout: {e.stdout}")
        return False
    except FileNotFoundError:
        print("❌ nmcli not found - NetworkManager not installed?")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def setup_home_wifi():
    """Main setup function"""
    print()
    
    networks_added = 0
    
    while networks_added < 2:  # Max 2 networks
        try:
            ssid, password = get_network_info()
            
            print(f"\nNetwork: '{ssid}'")
            save = input("Save this? (y/n): ").lower().strip()
            
            if save.startswith('y'):
                if add_home_wifi(ssid, password):
                    networks_added += 1
                    
                    if networks_added == 1:
                        backup = input("Add backup network? (y/n): ").lower().strip()
                        if not backup.startswith('y'):
                            break
            else:
                break
                
        except KeyboardInterrupt:
            print("\n❌ Cancelled")
            break
    
    if networks_added > 0:
        print(f"\n🎉 {networks_added} new network(s) saved!")
        print("At home: plug in robot, wait 3 minutes")
        
        # Show potential issues based on what they entered
        print("\n🆘 If it doesn't work:")
        print("• Wrong password (most common)")
        print("• Wrong network name")
        print("• Network requires login page")
    else:
        print("❌ No networks saved")

def show_saved_networks():
    """Show configured networks"""
    try:
        result = subprocess.run(['nmcli', '-f', 'NAME,TYPE', 'connection', 'show'],
                                capture_output=True, text=True, check=True)

        print("💾 Saved networks:")
        wifi_count = 0
        for line in result.stdout.split('\n')[1:]:
            if 'wifi' in line.lower() and line.strip():
                name = line.split()[0]
                if name and name != '--':
                    wifi_count += 1
                    print("  ",wifi_count," ", name)
        
        if wifi_count == 0:
            print("None")
            
    except subprocess.CalledProcessError:
        print("❌ Can't list networks")
