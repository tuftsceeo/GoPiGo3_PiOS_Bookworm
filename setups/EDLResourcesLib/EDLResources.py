from subprocess import Popen, PIPE
from picamera2 import Picamera2
import os, sys
import subprocess
import time
import threading


#resources file for EDL jupyter notebooks
#2023A

# defines an asynchronous stream capture of images
class AsyncCapture:
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

    def get_frame(self):
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

def switch_to_pi():
    sudoPassword = 'robots1234'
    command = 'su pi'.split()
    p = Popen(['sudo', '-S'] + command, stdin=PIPE, stderr=PIPE, universal_newlines=True)
    sudo_prompt = p.communicate(sudoPassword + '\n')[1]

def switch_to_jupyter():
    sudoPassword = 'jupyter'
    command = 'su jupyter'.split()
    p = Popen(['sudo', '-S'] + command, stdin=PIPE, stderr=PIPE, universal_newlines=True)
    sudo_prompt = p.communicate(sudoPassword + '\n')[1]

#shuts down pi
def shutdown_pi():
    subprocess.Popen(['sudo','shutdown','-h','now'])
    
import re
    
def add_new_wifi():
    switch_to_jupyter()

    ssid = input("Provide your wifi SSID (e.g. the name) then press enter: ")
    pwd = input("Provide your wifi password then press enter: ")
    command = ['sudo', 'sh', '-c', "wpa_passphrase %s %s >> /etc/wpa_supplicant/wpa_supplicant.conf"%(ssid, pwd)]

    cmd1 = Popen(command, shell = False, stdin=PIPE, stdout=PIPE, stderr=PIPE, universal_newlines=True)
    #output = cmd1.stdout.read()
    #print(output)
    time.sleep(1)
    #sudo_prompt = cmd1.communicate(sudo_password  + '\n')[1]
    #print(sudo_prompt)
    

def read_known_wifi():
    command = ['cat', "/etc/wpa_supplicant/wpa_supplicant.conf"]
    cmd2 = Popen(command, shell = False, universal_newlines=True, stdout=PIPE)
    output = cmd2.stdout.read() 
    output = re.split('network=', output)
    for new_net in output[::-1]:
        if "ssid" in new_net:
            new_net = re.sub(r'[\{\}\t]', '', new_net).strip(' \n\t').split()
            print("===========")
            for detail in new_net:
                if "ssid" in detail or "psk" in detail:
                    print(detail)
