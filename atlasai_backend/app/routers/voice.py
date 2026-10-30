import base64
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Body
from app.schemas.schemas import TranscribeResponse, SynthesizeRequest, SynthesizeResponse
from app.services.sarvam_service import sarvam_service

router = APIRouter(prefix="/api/voice", tags=["Voice & Multilingual AI"])


@router.post("/transcribe", response_model=TranscribeResponse)
async def transcribe_audio(
    file: Optional[UploadFile] = File(None),
    audio_base64: Optional[str] = Form(None),
    language_code: Optional[str] = Form(None)
):
    """
    Transcribes audio recording in Hindi, Marathi, or English using Sarvam AI STT.
    Accepts direct multipart file or base64 audio string.
    """
    audio_bytes = b""
    filename = "recording.wav"

    if file:
        audio_bytes = await file.read()
        filename = file.filename or "recording.wav"
    elif audio_base64:
        try:
            # Handle potential data URI scheme
            clean_b64 = audio_base64.split(",")[-1]
            audio_bytes = base64.b64decode(clean_b64)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid base64 audio encoding")
    else:
        # If neither provided, return demo sample
        return TranscribeResponse(
            transcript="₹499 कट गए लेकिन पेमेंट फेल हो गया, कृपया रिफंड दें (PAY1001)",
            detected_language="hi-IN",
            confidence=0.92
        )

    result = await sarvam_service.transcribe_audio(
        audio_bytes=audio_bytes,
        filename=filename,
        language_code=language_code
    )

    return TranscribeResponse(
        transcript=result["transcript"],
        detected_language=result["detected_language"],
        confidence=result.get("confidence", 0.95)
    )


@router.post("/synthesize", response_model=SynthesizeResponse)
async def synthesize_speech(req: SynthesizeRequest):
    """
    Synthesizes text into high-fidelity Indian-language speech using Sarvam Bulbul:v1 TTS.
    Returns playable audio base64 with format 'wav'.
    """
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    audio_b64, audio_fmt = await sarvam_service.synthesize_speech(
        text=req.text,
        language_code=req.language_code,
        speaker=req.speaker or "meera"
    )

    return SynthesizeResponse(
        audio_base64=audio_b64,
        format=audio_fmt
    )
