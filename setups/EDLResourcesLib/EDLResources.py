from subprocess import Popen, PIPE
from picamera2 import Picamera2
import os, sys
import subprocess
import time
import threading


#resources file for EDL jupyter notebooks
#2023A

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

#hides console output for some gopigo methods that like to be very verbose
class HiddenPrints:
    def __enter__(self):
        self._original_stdout = sys.stdout
        sys.stdout = open(os.devnull, 'w')

    def __exit__(self, exc_type, exc_val, exc_tb):
        sys.stdout.close()
        sys.stdout = self._original_stdout

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
