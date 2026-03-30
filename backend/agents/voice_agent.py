import asyncio
import edge_tts
import os
from datetime import datetime

class VoiceAgent:
    def __init__(self):
        self.voice = "tr-TR-AhmetNeural"
        self.rate = "+10%"

    async def generate_audio(self, text: str, project_name: str) -> str:
        """
        Metni edge-tts ile seslendirir ve tarih bazlı klasör yapısında saklar.
        """
        # Tarih ve dosya yolu hazırlama
        today = datetime.now().strftime("%Y-%m-%d")
        output_dir = os.path.join("output", today, project_name)
        os.makedirs(output_dir, exist_ok=True)
        
        file_path = os.path.join(output_dir, "voice.mp3")
        
        # Seslendirme işlemi
        communicate = edge_tts.Communicate(text, self.voice, rate=self.rate)
        await communicate.save(file_path)
        
        return file_path

if __name__ == "__main__":
    # Test
    agent = VoiceAgent()
    asyncio.run(agent.generate_audio("Bugün küresel petrol arzında kritik bir daralma yaşanıyor.", "test_proje"))
