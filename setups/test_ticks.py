
import easygopigo3 as easy
import time

# Global GPG 
try:
    gpg = easy.EasyGoPiGo3()
except Exception as e:
    print("GoPiGo3 cannot be instanstiated. Most likely wrong firmware version")
    print(e)
    exit()

gpg.WHEEL_BASE_WIDTH        # distance (mm) from left wheel to right wheel. This works with the initial GPG3 prototype. Will need to be adjusted.
gpg.WHEEL_DIAMETER            # wheel diameter (mm)
gpg.WHEEL_BASE_CIRCUMFERENCE  # The circumference of the circle the wheels will trace while turning (mm)
gpg.WHEEL_CIRCUMFERENCE      # The circumference of the wheels (mm)

gpg.MOTOR_GEAR_RATIO        # Motor gear ratio # 220 for Nicole's prototype
gpg.ENCODER_TICKS_PER_ROTATION # Encoder ticks per motor rotation (number of magnet positions) # 16 for early prototypes
gpg.MOTOR_TICKS_PER_DEGREE # encoder ticks per output shaft rotation degree

print("ENCODER_TICKS_PER_ROTATION:",gpg.ENCODER_TICKS_PER_ROTATION)
print("MOTOR_GEAR_RATIO:",gpg.MOTOR_GEAR_RATIO)
print("WHEEL_BASE_WIDTH:",gpg.WHEEL_BASE_WIDTH)
print("WHEEL_DIAMETER:",gpg.WHEEL_DIAMETER)

WheelTurnRotations_12INCH = ((12 * 2.54 * 10) / gpg.WHEEL_CIRCUMFERENCE) # 12 inches to cm to mm over wheel circumference
print(WheelTurnRotations_12INCH, "revolutions per foot")
EncoderTicks_12INCH = WheelTurnRotations_12INCH * 360 * gpg.MOTOR_TICKS_PER_DEGREE
print(EncoderTicks_12INCH, "ticks per foot")
time.sleep(1)
gpg.drive_inches(12)