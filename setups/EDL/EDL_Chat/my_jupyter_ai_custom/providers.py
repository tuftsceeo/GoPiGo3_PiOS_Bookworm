# At the very top of providers.py, before any other imports
import jupyter_ai.extension

# Store the original method
_original_show_help = jupyter_ai.extension.AiExtension._show_help_message

def _custom_show_help(self):
    """Override the initial help message"""
    # Get the default handler
    default_handler = self.settings["jai_chat_handlers"].get("default")
    if not default_handler:
        return
    
    # Send custom welcome message
    from jupyter_ai.models import AgentChatMessage
    import time
    import uuid
    
    custom_message = AgentChatMessage(
        id=str(uuid.uuid4()),
        time=time.time(),
        body="""Welcome to EDL Chat!

I'm here to help you program your GoPiGo3 robot. Just ask questions like:
- "How do I make my robot move forward?"
- "Show me obstacle avoidance code"
- "Help me use the camera"

Type your question below to get started!

(EDL Chat Active)""",
        reply_to="",
        persona={"name": "Jupyternaut EDL", "avatar_route": "api/ai/static/jupyternaut.svg"} 
         # Add required persona field
    )
    
    default_handler.broadcast_message(custom_message)

# Replace the method
jupyter_ai.extension.AiExtension._show_help_message = _custom_show_help

from jupyter_ai_magics import BaseProvider
from jupyter_ai_magics.providers import EnvAuthStrategy, TextField
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_openai import ChatOpenAI
from jupyter_ai.chat_handlers.base import BaseChatHandler
from jupyter_ai.chat_handlers.default import DefaultChatHandler
from jupyter_ai.chat_handlers.help import HelpChatHandler


# Keep your working SimpleChatProvider as-is
class SimpleChatProvider(BaseProvider, ChatOpenAI):
    id = "simple_custom_chat"
    name = "Simple Custom Chat"
    models = [
        "gpt-3.5-turbo",
        "gpt-4",
        "gpt-4o",
        "gpt-4o-mini",
    ]
    model_id_key = "model_name"
    pypi_package_deps = ["langchain_openai"]
    auth_strategy = EnvAuthStrategy(name="OPENAI_API_KEY")

    fields = [
        TextField(
            key="openai_api_base", label="Base API URL (optional)", format="text"
        ),
        TextField(
            key="openai_organization", label="Organization (optional)", format="text"
        ),
        TextField(key="openai_proxy", label="Proxy (optional)", format="text"),
    ]

    @classmethod
    def is_api_key_exc(cls, e: Exception):
        """
        Determine if the exception is an OpenAI API key error.
        """
        import openai

        if isinstance(e, openai.AuthenticationError):
            error_details = e.json_body.get("error", {})
            return error_details.get("code") == "invalid_api_key"
        return False

    def get_chat_prompt_template(self) -> ChatPromptTemplate:
        """
        Simple custom chat prompt template
        """
        return ChatPromptTemplate.from_messages([
            ("system", 
                "You are a helpful AI assistant specialized for Jupyter notebooks. "
                "You provide practical, actionable advice with code examples when relevant. "
                "ALWAYS end your responses with: '(Simple Chat Active)'"),
            MessagesPlaceholder(variable_name="history"),
            ("human", "{input}")
        ])


# Fixed EDL Chat provider
class EDLChatProvider(BaseProvider, ChatOpenAI):
    id = "edl_custom_chat"
    name = "EDL Chat"
    models = [
        "gpt-3.5-turbo",
        "gpt-4",
        "gpt-4o",
        "gpt-4o-mini",
    ]
    model_id_key = "model_name"
    pypi_package_deps = ["langchain_openai"]
    auth_strategy = EnvAuthStrategy(name="OPENAI_API_KEY")

    fields = [
        TextField(
            key="openai_api_base", label="Base API URL (optional)", format="text"
        ),
        TextField(
            key="openai_organization", label="Organization (optional)", format="text"
        ),
        TextField(key="openai_proxy", label="Proxy (optional)", format="text"),
    ]

    @classmethod
    def is_api_key_exc(cls, e: Exception):
        """
        Determine if the exception is an OpenAI API key error.
        """
        import openai

        if isinstance(e, openai.AuthenticationError):
            error_details = e.json_body.get("error", {})
            return error_details.get("code") == "invalid_api_key"
        return False

    def get_chat_prompt_template(self) -> ChatPromptTemplate:
        """EDL Chat prompt template"""
        # NOTE: Don't include {history} - DefaultChatHandler manages this
        return ChatPromptTemplate.from_messages([
            ("system", """You are an AI assistant specialized for EDL (Engineering Design Lab) precollege students using GoPiGo3 robots.

Your primary role is to help students explore robotics and the engineering design process. Focus on:

1. **Writing complete, functioning Python code** for GoPiGo3 robots
2. **Using simple, clear syntax** that novice programmers can understand
3. **Adding helpful comments** to explain what the code does
4. **Building student confidence and excitement** about robotics

IMPORTANT Robot Setup:
- Always initialize the robot with: `easyGPG = EasyGoPiGo3()`
- Import statements: `from easygopigo3 import EasyGoPiGo3`
- For special features like camera or audio, use EDLResources library

When students ask about features like:
- Camera/vision: Suggest using PiVideoStream from EDLResources
- Audio/speaking: Suggest using speak or robot_say from EDLResources (not Speaker class)
- Additional servos beyond SERVO1/SERVO2: Use GPIO pins 12 or 13 with piservo library
- GPIO components: Use RPi.GPIO for additional LEDs, buttons, etc.

CRITICAL CODING STYLE RULES:
- Use 'for' loops with range() for fixed iterations: for step in range(20):
- Use 'while' loops with counters and exit conditions for sensor/time-based tasks
- NEVER use 'while True' - always have bounded execution (max steps or time limit)
- NO try/except blocks - let students see real errors
- Use try/finally ONLY for cleanup: camera.stop(), GPIO.cleanup(), robot.stop()
- Increment counters with: step = step + 1 (NOT step += 1)
- Use string concatenation: "Distance: " + str(distance) + " cm" (NOT f-strings)
- NO dictionaries, classes, or advanced Python features
- Comment major algorithm steps, not every line

COMMON PATTERNS:
- For audio projects: quiet_mode() at start, speak("message") for feedback
- For camera: camera = PiVideoStream(resolution=(320, 240)), camera.start(), camera.stop()
- For GPIO: GPIO.setmode(GPIO.BCM), GPIO.setup(), GPIO.cleanup()
- Variable names: step, count, distance, frame, detection_count, etc.
- Import time as: from time import sleep (then use sleep() directly)
- Always include sleep() delays for timing control

EXAMPLE CODE PATTERNS TO FOLLOW:

# Fixed iterations with for loop:
for step in range(20):
    distance = distance_sensor.read()
    print("Step", step + 1, "- Distance:", distance, "cm")
    easyGPG.drive_cm(10)
    sleep(0.5)

# Sensor-based with while loop and counter:
detection_count = 0
while detection_count < 30:
    frame = camera.read()
    if frame is not None:
        # Process frame
        detection_count = detection_count + 1
    sleep(0.3)

# Cleanup pattern with try/finally:
try:
    # Main robot behavior
    for i in range(10):
        easyGPG.forward()
        sleep(1)
finally:
    camera.stop()
    easyGPG.stop()

If you're unsure about specific EDLResources functions or need detailed documentation, tell students:
"For detailed documentation about [feature], try asking: /ask how do I use [feature]"

If you do not know the answer to a question, always tell the truth, then suggest the student ask their instructor. 

Your prior conversation with the student follows.

ALWAYS end your responses with: '(EDL Chat Active)'"""),
        MessagesPlaceholder(variable_name="history"),
        ("human", "{input}")
        ])

# Simplified chat handler that works WITH DefaultChatHandler
class EDLChatHandler(DefaultChatHandler):
    """Chat handler that adds keyword detection for EDLResources"""
    
    id = "default"
    name = "EDL Chat with Smart Context"
    help = "Chat with smart detection for EDLResources questions"
    
    # Keywords that trigger vector database search
    EDL_KEYWORDS = [
        'edlresources', 'pivideostream', 'camera', 'vision', 'speak',
        'quiet_mode', 'audio', 'servo', 'gpio', 'button', 'led',
        'pivideo', 'stream', 'opencv', 'cv2', 'image', 'frame',
        'april', 'tag', 'apriltag', 'detector', 'color', 'tracking',
        'parallel', 'streaming', 'ip_announcement', 'piservo',
        'rpi.gpio', 'gpio.setup', 'gpio.output', 'breadboard'
    ]
    
    def __init__(self, *args, **kwargs):
        """Initialize the handler"""
        super().__init__(*args, **kwargs)
        self._last_context = ""  # Cache last context to reduce searches
    
    async def process_message(self, message):
        """Process message with smart context detection"""
        
        # Intercept /help command
        if message.body.strip() == '/help' or message.body.strip().startswith('/help '):
            help_text = """Welcome to EDL Chat!

I'm here to help you with GoPiGo3 robot programming. Just type your questions!

Examples:
- "How do I make my robot move forward?"
- "Help me create obstacle avoidance"
- "Show me distance sensor code"

Useful commands:
- /ask - Ask about robot functions
- /clear - Clear chat

Ready to code! Type your question below.

(EDL Chat Active)"""
            self.reply(help_text, message)
            return  # Don't process further
        
        # Rest of your existing code...
        # Check if message contains EDL-related keywords
        message_lower = message.body.lower()
        needs_context = any(keyword in message_lower for keyword in self.EDL_KEYWORDS)
        
        # Get context only if needed
        context = ""
        if needs_context:
            context = await self._get_edl_context(message.body)
            self._last_context = context
        
        # For follow-up questions, reuse context if no new keywords
        elif self._last_context and ("that" in message_lower or "it" in message_lower):
            context = self._last_context
        
        # Let the parent class handle everything else
        if context:
            # Inject context into the message
            enhanced_message = f"{message.body}\n\n[Context from EDLResources documentation:\n{context}]"
            message.body = enhanced_message
        
        # Use parent's process_message
        await super().process_message(message)
            
    async def _get_edl_context(self, query: str) -> str:
        """Get relevant context from vector database"""
        try:
            # Access vector database through the proper path
            vector_db = None
            
            # Method 1: Through settings
            if hasattr(self, 'settings') and 'jai_core' in self.settings:
                jai_core = self.settings['jai_core']
                if hasattr(jai_core, 'vector_db'):
                    vector_db = jai_core.vector_db
            
            # Method 2: Through root chat handlers (for /ask compatibility)
            if not vector_db and hasattr(self, 'root_chat_handlers'):
                ask_handler = self.root_chat_handlers.get('ask')
                if ask_handler and hasattr(ask_handler, 'index'):
                    vector_db = ask_handler.index
            
            if not vector_db:
                return ""
            
            # Create retriever and get relevant docs
            retriever = vector_db.as_retriever(
                search_type="similarity",
                search_kwargs={"k": 2}  # Only get 2 most relevant docs to save tokens
            )
            
            docs = retriever.get_relevant_documents(query)
            
            if docs:
                # Format context concisely
                context_parts = []
                for doc in docs[:2]:  # Limit to 2 docs
                    # Extract just the most relevant part
                    content = doc.page_content[:500]  # Limit length
                    context_parts.append(content)
                
                return "\n---\n".join(context_parts)
            
            return ""
            
        except Exception as e:
            print(f"DEBUG: Error getting EDL context: {e}")
            return ""
            

from jupyter_ai.chat_handlers.base import BaseChatHandler, SlashCommandRoutingType
from jupyter_ai.models import HumanChatMessage

# Add this to your existing providers.py file
class EDLHelpHandler(BaseChatHandler):
    """Custom help handler for EDL students"""
    
    id = "help"
    name = "Help"
    help = "Display help message"
    routing_type = SlashCommandRoutingType(slash_id="help")
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
    
    async def process_message(self, message: HumanChatMessage):
        """Process help command"""
        help_text = """Welcome to EDL Chat!

I'm here to help you with GoPiGo3 robot programming. Just type your questions!

Examples:
- "How do I make my robot move forward?"
- "Help me create obstacle avoidance"  
- "Show me distance sensor code"

Useful commands:
- /ask - Ask about robot functions
- /clear - Clear chat

Ready to code! Type your question below.

(EDL Chat Active)"""
        
        self.reply(help_text, message)
