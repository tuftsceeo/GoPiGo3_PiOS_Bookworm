# Attempts / Notes for making a GoPiGo3 AI tutor for motion control
# NOT CURRENTLY WORKING
# =================
echo "Notes for up GoPiGo3 AI Tutoring System for Motion Control"
echo "NOT WORKING YET - stop running this script if you see this message"
echo "============================"
sleep 15
sudo mkdir -p /home/jupyter/gopigo3_tutors
sudo chown -R jupyter:jupyter /home/jupyter/gopigo3_tutors
cd /home/jupyter/gopigo3_tutors

sudo -u jupyter tee /home/jupyter/gopigo3_tutors/__init__.py << 'EOF'
"""
GoPiGo3 AI Tutoring System - Starting with Motion Specialist
"""
__version__ = "1.0.0"
EOF

sudo -u jupyter tee /home/jupyter/gopigo3_tutors/knowledge_base/motion_reference.md << 'EOF'
"""
Motion Specialist - Expert in GoPiGo3 movement and navigation
Simple version that will evolve into the full auto-loading system
"""

from jupyter_ai.chat_handlers.base import BaseChatHandler, SlashCommandRoutingType
from jupyter_ai.models import HumanChatMessage

class MotionTutor(BaseChatHandler):
    """Motion specialist for GoPiGo3 robot movement"""
    
    id = "motion_tutor"
    name = "Motion Specialist"
    help = "Expert in GoPiGo3 movement, navigation, and motor control"
    routing_type = SlashCommandRoutingType(slash_id="motion")
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # This structure is ready for knowledge base integration later
        self.motion_knowledge = self._load_motion_knowledge()
    
    def _load_motion_knowledge(self):
        """Load motion-specific knowledge (will become vector DB later)"""
        return {
            "basic_commands": {
                "drive_cm": "Move robot forward/backward by distance in cm. Positive=forward, negative=backward",
                "turn_degrees": "Turn robot by angle in degrees. Positive=right, negative=left", 
                "set_speed": "Set robot speed in degrees per second. Default is 300",
                "stop": "Stop all robot movement immediately"
            },
            "common_issues": {
                "inaccurate_distance": "Robot movement accuracy varies - this is normal! Use calibration or multiple small moves",
                "robot_not_moving": "Check battery level, connections, and try robot.reset_all()",
                "too_fast": "Use robot.set_speed(150) to slow down for better control"
            },
            "concepts": {
                "differential_steering": "Robot turns by making wheels move at different speeds",
                "encoders": "Motor encoders count wheel rotations for precise movement",
                "calibration": "Each robot is slightly different - tune movements for your specific robot"
            }
        }
    
    def _get_relevant_info(self, query):
        """Simple keyword matching (will become vector search later)"""
        query_lower = query.lower()
        relevant_info = []
        
        # Check for basic commands
        for cmd, desc in self.motion_knowledge["basic_commands"].items():
            if cmd in query_lower or any(word in query_lower for word in cmd.split('_')):
                relevant_info.append(f"**{cmd}()**: {desc}")
        
        # Check for common issues
        issue_keywords = {
            "inaccurate_distance": ["accurate", "precise", "wrong distance", "not stopping", "overshooting"],
            "robot_not_moving": ["not moving", "won't move", "stuck", "not responding"],
            "too_fast": ["too fast", "slow down", "speed", "control"]
        }
        
        for issue, keywords in issue_keywords.items():
            if any(keyword in query_lower for keyword in keywords):
                relevant_info.append(f"**Common Issue**: {self.motion_knowledge['common_issues'][issue]}")
        
        return relevant_info
    
    def _detect_escalation_needs(self, message):
        """Detect if student needs hands-on help"""
        escalation_keywords = [
            "robot won't turn on", "robot not responding", "wheels not turning",
            "motor not working", "battery", "broken", "damaged", "smoke", "sparks"
        ]
        
        return any(keyword in message.lower() for keyword in escalation_keywords)
    
    async def process_message(self, message: HumanChatMessage):
        """Process student question about robot movement"""
        
        # Check if this needs escalation to teaching staff
        if self._detect_escalation_needs(message.body):
            escalation_response = """
🔧 **Hardware Issue Detected**

This sounds like a hands-on hardware problem that needs direct attention.

**Please get a teaching fellow** and let them know:
- You're working on robot movement
- Hardware issue: robot hardware not responding properly
- The robot needs physical inspection

Hardware problems are usually quick fixes once we can see the robot!

**While you wait**: Think about what movement you want to accomplish once it's working.
            """
            await self.reply(escalation_response, message)
            return
        
        # Get relevant information
        relevant_info = self._get_relevant_info(message.body)
        
        # Build context for the LLM
        context = ""
        if relevant_info:
            context = f"""
RELEVANT GOPIGO3 MOTION INFO:
{chr(10).join(relevant_info)}

"""
        
        system_prompt = f"""You are a robotics motion expert helping a high school student with GoPiGo3 robot movement.

TEACHING APPROACH:
- Always start with "What do you want the robot to DO?"
- Use simple analogies (robot like a remote control car)
- Explain the concept before showing code
- Address movement accuracy issues positively (it's normal!)
- Encourage experimentation with different speeds and distances
- Provide working code examples they can try immediately

STUDENT CONTEXT:
- Learning robotics in a 2-week intensive program
- May be beginner or have some experience
- Using GoPiGo3 robot with Python
- Wants to make the robot move in specific ways

{context}STUDENT QUESTION: {message.body}

Help them understand robot movement concepts and provide practical solutions.
If they're having hardware issues, you've already escalated appropriately.
Make robot movement feel fun and achievable!"""

        await self.stream_reply({"prompt": system_prompt}, message)
EOF

sudo -u jupyter tee /home/jupyter/gopigo3_tutors/setup.py << 'EOF'
from setuptools import setup, find_packages

setup(
    name="gopigo3-tutors",
    version="1.0.0",
    description="AI tutoring agents for GoPiGo3 robotics education",
    packages=find_packages(),
    install_requires=[
        "jupyter-ai",
    ],
    entry_points={
        "jupyter_ai.chat_handlers": [
            "motion = gopigo3_tutors.motion_tutor:MotionTutor",
        ]
    },
)
EOF

# Install the agent package with system override
cd /home/jupyter/gopigo3_tutors
sudo -u jupyter pip3 install -e . --break-system-packages

sudo systemctl restart jupyter.service

sudo -u jupyter tee /home/jupyter/.jupyter/jupyter_ai_config.py << 'EOF'
c = get_config()

# Configure the model provider and model
c.AiExtension.default_language_model = "openai-chat:gpt-3.5-turbo"

# Enable our custom motion agent
c.AiExtension.allowed_chat_handlers = [
    "motion",    # Our custom motion agent
    "learn",     # Default Jupyter AI agents
    "ask",
    "generate", 
    "explain",
    "fix"
]

EOF

sudo -u jupyter mkdir -p /home/jupyter/gopigo3_tutors/knowledge_base/motion

sudo chgrp -R users /home 
sudo chmod -R g+rwx /home



sudo -u jupyter tee /home/jupyter/gopigo3_tutors/knowledge_base/motion/basic_driving.md << 'EOF'
# GoPiGo3 Motion Control Knowledge Base

## Robot Initialization
```python
from easygopigo3 import EasyGoPiGo3
easyGPG = EasyGoPiGo3()
```

## Basic Movement Commands

### drive_cm(distance, blocking=True)
Move robot forward or backward by distance in centimeters.
- **distance**: float - Distance in cm (positive=forward, negative=backward)
- **blocking**: bool - Wait for completion (default: True)

```python
easyGPG.drive_cm(20)    # Forward 20cm
easyGPG.drive_cm(-15)   # Backward 15cm
```

### turn_degrees(degrees, blocking=True)
Turn robot by specified angle in degrees.
- **degrees**: float - Angle in degrees (positive=right, negative=left)
- **blocking**: bool - Wait for completion (default: True)

```python
easyGPG.turn_degrees(90)    # Turn right 90°
easyGPG.turn_degrees(-45)   # Turn left 45°
```

### drive_inches(distance, blocking=True)
Move robot by distance in inches.
```python
easyGPG.drive_inches(8)     # Forward 8 inches
```

## Speed Control

### set_speed(speed)
Set robot movement speed in degrees per second.
- **Default speed**: 300 degrees/second
- **Recommended range**: 50-600 degrees/second

```python
easyGPG.set_speed(150)      # Half speed for precision
easyGPG.set_speed(600)      # Double speed (may be inaccurate)
```

## Continuous Movement

### forward(), backward(), left(), right()
Start continuous movement (non-blocking).
```python
easyGPG.forward()           # Start moving forward
time.sleep(2)               # Move for 2 seconds
easyGPG.stop()              # Stop movement
```

### stop()
Stop all robot movement immediately.
```python
easyGPG.stop()
```

## Advanced Movement

### steer(left_percent, right_percent)
Control individual wheel speeds.
- **Parameters**: -100 to 100 (percentage of max speed)

```python
easyGPG.steer(50, 100)      # Gentle right turn while moving
easyGPG.steer(-50, 50)      # Spin left in place
```

## Movement Patterns

### Square Pattern
```python
for i in range(4):
    easyGPG.drive_cm(20)
    easyGPG.turn_degrees(90)
```

### Circle Pattern
```python
for i in range(36):
    easyGPG.drive_cm(3)
    easyGPG.turn_degrees(10)
```

## Common Issues & Solutions

### Robot doesn't move exact distances
**Normal behavior** - Each robot is slightly different.
**Solutions**:
- Use smaller movements and combine them
- Calibrate specific distances for your robot
- Use encoder feedback for precision

### Robot moves too fast to control
```python
easyGPG.set_speed(150)      # Slow down for better control
```

### Robot not responding to movement commands
**Check**:
- Battery level (should be >7V)
- Motor connections
- Try `easyGPG.reset_all()` first

### Inconsistent turning
**Causes**: Surface friction, battery level, wheel wear
**Solutions**:
- Test on consistent surfaces
- Calibrate turn angles for your robot
- Ensure wheels are clean

## Safety Notes
- Always use `easyGPG.stop()` to end programs
- Test movements in open areas first
- Start with slow speeds and small distances
- Continuous movement commands need manual stopping

## Troubleshooting Commands
```python
# Reset all systems
easyGPG.reset_all()

# Check battery voltage
voltage = easyGPG.volt()
print(f"Battery: {voltage}V")

# Test basic movement
easyGPG.drive_cm(5)         # Small test movement
```

## Differential Steering Concept
GoPiGo3 uses **differential steering** - like a tank or wheelchair:
- Two powered wheels control movement
- Caster wheel provides stability
- Turn by making wheels move at different speeds
- Spin in place by moving wheels in opposite directions

This is different from car steering where front wheels turn while rear wheels power the vehicle.
EOF
