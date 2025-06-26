# GoPiGo3 Robot Programming Guide - Student Kit Components

## Quick Start - Robot Initialization

**Standard way to initialize your GoPiGo3 robot:**

```python
from easygopigo3 import EasyGoPiGo3
import time

# Initialize the robot
easyGPG = EasyGoPiGo3()
easyGPG.reset_all()        # Clear any previous configurations
easyGPG.reset_encoders()   # Reset encoder values to zero
```

## Hardware Ports Overview

Your GoPiGo3 kit includes these connection ports:

- **"SERVO1" and "SERVO2"** - For your two servo motors
- **"I2C"** - For your distance sensor (uses special di_sensors library)
- **GPIO pins** - For your circuit kit components (LEDs, buttons, resistors)

Example of using port identifiers:
```python
# Distance sensor uses separate library (not through easyGPG)
from di_sensors.easy_distance_sensor import EasyDistanceSensor
distance_sensor = EasyDistanceSensor()  # Automatically connects to I2C

# Servos connect through easyGPG object
servo_one = easyGPG.init_servo("SERVO1")
servo_two = easyGPG.init_servo("SERVO2")
```

## Chapter 2: Motors and Movement

### Basic Movement Commands

**Important:** Your robot has a default speed of 300 DPS (degrees per second). You don't need to set speed unless you want to change it.

```python
from easygopigo3 import EasyGoPiGo3
import time

easyGPG = EasyGoPiGo3()

# Basic movement commands
easyGPG.forward()       # Move forward at current speed
easyGPG.backward()      # Move backward at current speed
easyGPG.left()          # Turn left (only left motor runs)
easyGPG.right()         # Turn right (only right motor runs)
easyGPG.spin_left()     # Spin left in place (both motors)
easyGPG.spin_right()    # Spin right in place (both motors)
easyGPG.stop()          # Stop all movement
```

**Critical:** Always end movement code with `easyGPG.stop()` to prevent runaway robots!

### Time-Based Movement

```python
# Move for a specific time period
easyGPG.forward()
time.sleep(2)      # Move forward for 2 seconds
easyGPG.stop()     # Always stop!

# Turn for a specific time
easyGPG.spin_right()
time.sleep(1)      # Spin for 1 second
easyGPG.stop()
```

### Precise Movement with Encoders

```python
# Move exact distances (automatically stops when complete)
easyGPG.drive_cm(30)        # Drive forward 30 centimeters
easyGPG.drive_inches(12)    # Drive forward 12 inches
easyGPG.turn_degrees(90)    # Turn 90 degrees (positive = right, negative = left)
easyGPG.drive_degrees(360)  # Drive for one full wheel rotation

# Example: Drive in a square
for i in range(4):
    easyGPG.drive_cm(20)      # Drive forward 20 cm
    easyGPG.turn_degrees(90)  # Turn right 90 degrees
```

### Speed Control

**Note:** Changing speed does NOT start the robot moving - it sets the target speed for movement commands.

```python
# Default speed is 300 DPS - you only need to change if desired
easyGPG.set_speed(150)      # Slower than default
easyGPG.set_speed(600)      # Faster than default
easyGPG.set_speed(300)      # Back to default

# Get current speed setting
current_speed = easyGPG.get_speed()
print(f"Current speed: {current_speed} DPS")

# Reset to default speed (300 DPS)
easyGPG.reset_speed()

# Speed change does NOT start movement!
easyGPG.set_speed(150)    # Robot still stopped
easyGPG.forward()         # NOW robot moves at 150 DPS
```

### Working with Motor Encoders

```python
# Reset encoder values to zero
easyGPG.reset_encoders()

# Read current encoder values (returns tuple: left, right)
left_encoder, right_encoder = easyGPG.read_encoders()
print(f"Left motor: {left_encoder} degrees, Right motor: {right_encoder} degrees")

# Example: Move until motors have rotated 360 degrees
easyGPG.reset_encoders()
easyGPG.forward()
while not easyGPG.target_reached(360, 360):  # Wait for one full rotation
    time.sleep(0.05)
easyGPG.stop()
```

### Advanced Movement Control

```python
# Control individual motor percentages
easyGPG.steer(50, 100)     # Left motor 50%, right motor 100%
easyGPG.steer(-100, 100)   # Left motor backward, right forward (spin left)

# Precise orbiting around objects
easyGPG.orbit(180, radius_cm=30)  # Half circle with 30cm radius
```

## Servo Motors (Chapter 2)

Your kit includes two servo motors for precise positioning:

```python
# Initialize servo motors
servo_one = easyGPG.init_servo("SERVO1")
servo_two = easyGPG.init_servo("SERVO2")

# Control servo position (0-180 degrees)
servo_one.rotate_servo(90)   # Center position
servo_one.rotate_servo(0)    # One extreme position
servo_one.rotate_servo(180)  # Other extreme position

# Servo movement example - sweep back and forth
for angle in range(0, 181, 10):  # 0 to 180 in steps of 10
    servo_one.rotate_servo(angle)
    time.sleep(0.1)

# Reset to center position
servo_one.reset_servo()  # Same as rotate_servo(90)

# Disable servo (allows manual movement)
servo_one.disable_servo()
```

## Built-in LEDs and Visual Feedback

### Eye LEDs (RGB) - Primary LEDs
When students refer to "LEDs" without specification, these are typically what they mean:

```python
# Set eye colors (RGB tuples: red, green, blue from 0-255)
easyGPG.set_eye_color((255, 0, 0))        # Red eyes
easyGPG.set_eye_color((0, 255, 0))        # Green eyes  
easyGPG.set_eye_color((0, 0, 255))        # Blue eyes
easyGPG.set_eye_color((255, 255, 0))      # Yellow eyes
easyGPG.set_eye_color((0, 255, 255))      # Cyan eyes (default)

# Control individual eyes
easyGPG.set_left_eye_color((255, 0, 0))   # Red left eye
easyGPG.set_right_eye_color((0, 255, 0))  # Green right eye

# Turn eyes on/off
easyGPG.open_eyes()        # Turn on both eyes
easyGPG.close_eyes()       # Turn off both eyes
easyGPG.open_left_eye()    # Turn on left eye only
easyGPG.close_right_eye()  # Turn off right eye only
```

### Blinker LEDs (Binary On/Off)
For simple on/off LED control:

```python
# Control the red blinker LEDs (binary on/off only)
easyGPG.blinker_on(0)      # Turn on right blinker
easyGPG.blinker_on(1)      # Turn on left blinker  
easyGPG.blinker_off(0)     # Turn off right blinker
easyGPG.blinker_off(1)     # Turn off left blinker

# You can also use string identifiers
easyGPG.blinker_on("right")
easyGPG.blinker_on("left")
easyGPG.blinker_off("right")
easyGPG.blinker_off("left")

# Example: Blinking turn signals
easyGPG.blinker_on("right")
easyGPG.turn_degrees(90)  # Turn right
easyGPG.blinker_off("right")
```

## Chapter 3: Distance Sensor

Your kit includes a DI-Sensors distance sensor that connects to the I2C port:

### Basic Distance Sensor Usage (Recommended for Beginners)

```python
# Import the easy distance sensor (separate from easyGPG)
from di_sensors.easy_distance_sensor import EasyDistanceSensor
from easygopigo3 import EasyGoPiGo3
import time

# Initialize robot and distance sensor separately
easyGPG = EasyGoPiGo3()
distance_sensor = EasyDistanceSensor()  # Automatically connects to I2C

# Read distance in different units
distance_cm = distance_sensor.read()          # Centimeters (0-230 cm)
distance_mm = distance_sensor.read_mm()       # Millimeters (5-2300 mm)
distance_inches = distance_sensor.read_inches()  # Inches (0-90 inches)

print(f"Distance: {distance_cm} cm")

# Note: Out of range values return 300 (cm), 3000 (mm), or >90 (inches)
```

### Simple Distance Reading Example

```python
from di_sensors.easy_distance_sensor import EasyDistanceSensor
from time import sleep

# Create distance sensor object
my_sensor = EasyDistanceSensor()

# Read sensor continuously
while True:
    distance = my_sensor.read()
    print(f"Distance from object: {distance} cm")
    sleep(0.1)
```

### Basic Obstacle Avoidance Example

```python
from easygopigo3 import EasyGoPiGo3
from di_sensors.easy_distance_sensor import EasyDistanceSensor
import time

# Initialize robot and sensor
easyGPG = EasyGoPiGo3()
distance_sensor = EasyDistanceSensor()

easyGPG.set_speed(200)  # Slower speed for safety

while True:
    distance = distance_sensor.read()
    print(f"Distance: {distance} cm")
    
    # Check if reading is valid (not out of range)
    if distance == 300:  # Out of range reading
        print("No obstacle detected in range")
        easyGPG.forward()
        easyGPG.set_eye_color((0, 255, 255))  # Cyan eyes = exploring
    elif distance > 20:  # Clear path ahead
        easyGPG.forward()
        easyGPG.set_eye_color((0, 255, 0))    # Green eyes = go
    else:  # Obstacle detected
        easyGPG.stop()
        easyGPG.set_eye_color((255, 0, 0))    # Red eyes = stop
        easyGPG.turn_degrees(90)              # Turn right
        time.sleep(0.5)
    
    time.sleep(0.1)  # Small delay
```

### Advanced Distance Sensor Usage (Optional)

For students who want maximum performance and control:

```python
from di_sensors.distance_sensor import DistanceSensor
from easygopigo3 import EasyGoPiGo3
import time

easyGPG = EasyGoPiGo3()
ds = DistanceSensor()

# Start continuous readings (faster than single readings)
ds.start_continuous(period_ms=50)  # Take reading every 50ms

while True:
    try:
        # Read distance in millimeters
        distance_mm = ds.read_range_continuous()
        distance_cm = distance_mm / 10  # Convert to cm
        
        print(f"Distance: {distance_cm:.1f} cm")
        
        # Your robot logic here
        if distance_cm > 20:
            easyGPG.forward()
        else:
            easyGPG.stop()
            
    except OSError as e:
        print(f"Sensor error: {e}")
        easyGPG.stop()
        break
    
    time.sleep(0.05)  # Match the sensor reading period
```

## Chapter 3: GPIO Circuit Components

Your circuit kit includes LEDs, resistors, and buttons that connect to GPIO pins:

### GPIO LEDs (Binary On/Off)
For LEDs in your circuit kit connected to GPIO pins:

```python
# These would be used with GPIO pins, not the robot's built-in ports
# Example assumes LED connected to GPIO pin 18
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)

# Control GPIO LED
GPIO.output(18, GPIO.HIGH)  # Turn on
GPIO.output(18, GPIO.LOW)   # Turn off

# Always cleanup when done
GPIO.cleanup()
```

### GPIO Buttons
For buttons in your circuit kit:

```python
# Example assumes button connected to GPIO pin 24
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(24, GPIO.IN, pull_up_down=GPIO.PUD_UP)

# Read button state
if GPIO.input(24) == GPIO.LOW:  # Button pressed (assuming pull-up)
    print("Button pressed!")
    easyGPG.forward()
else:
    print("Button not pressed")
    easyGPG.stop()

GPIO.cleanup()
```

## System Information and Debugging

```python
# Check battery voltage
voltage = easyGPG.volt()
print(f"Battery voltage: {voltage}V")

# If voltage is low (below ~7V), charge the battery!
if voltage < 7.0:
    print("Battery low - please charge!")
```

## Common Example Programs

### Robot Pet (Follows and Responds)
```python
from easygopigo3 import EasyGoPiGo3
from di_sensors.easy_distance_sensor import EasyDistanceSensor
import time

easyGPG = EasyGoPiGo3()
distance_sensor = EasyDistanceSensor()

while True:
    distance = distance_sensor.read()
    
    # Handle out-of-range readings
    if distance == 300:  # No obstacle in range
        easyGPG.set_eye_color((0, 0, 255))    # Blue eyes - searching
        easyGPG.spin_right()  # Look around
        time.sleep(0.5)
        easyGPG.stop()
        
    elif distance < 15:  # Too close - back away
        easyGPG.set_eye_color((255, 0, 0))    # Red eyes
        easyGPG.backward()
        time.sleep(0.5)
        easyGPG.stop()
        
    elif distance > 50:  # Too far - move closer  
        easyGPG.set_eye_color((255, 255, 0))  # Yellow eyes
        easyGPG.forward()
        
    else:  # Perfect distance - happy
        easyGPG.set_eye_color((0, 255, 0))    # Green eyes
        easyGPG.stop()
        # Wag servo like a tail
        servo = easyGPG.init_servo("SERVO1")
        for _ in range(3):
            servo.rotate_servo(60)
            time.sleep(0.2)
            servo.rotate_servo(120)
            time.sleep(0.2)
    
    time.sleep(0.1)
```

### Dancing Robot
```python
from easygopigo3 import EasyGoPiGo3
import time

easyGPG = EasyGoPiGo3()
servo_one = easyGPG.init_servo("SERVO1")
servo_two = easyGPG.init_servo("SERVO2")

# Dance routine
moves = [
    ("spin_right", 1, (255, 0, 0)),    # Spin right, red eyes
    ("spin_left", 1, (0, 255, 0)),     # Spin left, green eyes  
    ("forward", 0.5, (0, 0, 255)),     # Forward, blue eyes
    ("backward", 0.5, (255, 255, 0))   # Backward, yellow eyes
]

for move, duration, eye_color in moves:
    easyGPG.set_eye_color(eye_color)
    getattr(easyGPG, move)()  # Call the movement method
    
    # Move servos while dancing
    servo_one.rotate_servo(45)
    servo_two.rotate_servo(135)
    time.sleep(duration / 2)
    
    servo_one.rotate_servo(135)
    servo_two.rotate_servo(45)
    time.sleep(duration / 2)
    
    easyGPG.stop()

# Reset servos and eyes
servo_one.reset_servo()
servo_two.reset_servo()
easyGPG.close_eyes()
```

## Troubleshooting Common Issues

### Robot Not Moving
1. **Check battery**: `voltage = easyGPG.volt()` (should be > 7V)
2. **Verify speed is reasonable**: `easyGPG.set_speed(300)` 
3. **Ensure stop() isn't called immediately**: Check your code flow
4. **Remember**: `set_speed()` doesn't start movement, only sets target speed

### Distance Sensor Problems
1. **Check import and initialization**:
   ```python
   from di_sensors.easy_distance_sensor import EasyDistanceSensor
   distance_sensor = EasyDistanceSensor()  # Note: separate from easyGPG
   ```
2. **Handle out-of-range readings**: 
   - `read()` returns 300 cm when no obstacle detected
   - `read_mm()` returns 3000 mm when out of range
   - `read_inches()` returns >90 inches when out of range
3. **Check connections**: Sensor should be connected to I2C port
4. **Verify readings make sense**: Normal range is 0-230 cm

### LED Confusion
- **Eye LEDs**: RGB color control - `easyGPG.set_eye_color((r, g, b))`
- **Blinker LEDs**: Binary on/off - `easyGPG.blinker_on(0)` 
- **GPIO LEDs**: Circuit kit LEDs use `RPi.GPIO` library

### Servo Issues
1. **Check port**: "SERVO1" or "SERVO2" only
2. **Valid angles**: 0-180 degrees only
3. **Power**: Servos need good battery voltage

### Encoder Unexpected Values
1. **Reset before use**: `easyGPG.reset_encoders()`
2. **Check for wheel slip**: Smooth surfaces can cause issues
3. **Use blocking movements**: `easyGPG.drive_cm(30, blocking=True)`

## Best Practices

### Standard Initialization Pattern
```python
from easygopigo3 import EasyGoPiGo3
from di_sensors.easy_distance_sensor import EasyDistanceSensor
import time

# Always start with this pattern
easyGPG = EasyGoPiGo3()
easyGPG.reset_all()
easyGPG.reset_encoders()

# Initialize distance sensor (separate from easyGPG)
distance_sensor = EasyDistanceSensor()
```

### Safe Movement Pattern
```python
# Time-based movement
easyGPG.forward()
time.sleep(2)
easyGPG.stop()  # Always stop!

# OR use precise movement (auto-stops)
easyGPG.drive_cm(30)  # Automatically stops when complete
```

### Sensor Reading with Safety
```python
from di_sensors.easy_distance_sensor import EasyDistanceSensor

distance_sensor = EasyDistanceSensor()

while True:
    try:
        distance = distance_sensor.read()
        
        # Handle out-of-range readings
        if distance == 300:
            print("No obstacle in sensor range")
        else:
            print(f"Distance: {distance} cm")
        
        # Your logic here
        time.sleep(0.1)  # Always include small delay
    except KeyboardInterrupt:
        easyGPG.stop()
        easyGPG.close_eyes()
        break
    except Exception as e:
        print(f"Sensor error: {e}")
        easyGPG.stop()
```

---

## Additional Components for Final Projects

**Note**: Additional sensors and components are available for final projects and will be covered in separate documentation, including:
- Light sensors, sound sensors, motion sensors
- Temperature/humidity sensors  
- Remote control capabilities
- Advanced GPIO components
- Communication between robots
- Web interfaces and APIs

For final project extensions, refer to the additional project documentation.