import asyncio
import logging
from datetime import datetime
from pyzeebe import ZeebeWorker, Job, create_insecure_channel

# إعداد Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


async def main():
    """Worker لإرسال التذكيرات"""

    # الاتصال بـ Zeebe
    channel = create_insecure_channel(grpc_address="localhost:26500")
    worker = ZeebeWorker(channel)

    @worker.task(task_type="send-reminder", max_jobs_to_activate=5)
    async def send_reminder(job: Job):
        """
        إرسال تذكير للعميل قبل يوم من موعد المغادرة
        """
        try:
            logger.info(f"📧 Processing send-reminder job: {job.key}")

            # الحصول على البيانات من Process Variables
            owner_name = job.variables.get("ownerName", "Уважаемый клиент")
            owner_email = job.variables.get("ownerEmail", "")
            pet_name = job.variables.get("petName", "питомец")
            checkout_date = job.variables.get("checkOutDate", "")
            room_number = job.variables.get("roomNumber", "")

            logger.info(f"📋 Reminder Details:")
            logger.info(f"  - Owner: {owner_name}")
            logger.info(f"  - Email: {owner_email}")
            logger.info(f"  - Pet: {pet_name}")
            logger.info(f"  - Checkout Date: {checkout_date}")
            logger.info(f"  - Room: {room_number}")

            # محاكاة إرسال البريد الإلكتروني
            email_content = f"""
            Здравствуйте, {owner_name}!
            
            Напоминаем, что завтра {checkout_date} — день выезда вашего питомца {pet_name}.
            
            Номер: {room_number}
            
            Пожалуйста, приезжайте в удобное для вас время с 9:00 до 20:00.
            
            С уважением,
            Отель для домашних животных 🏨
            """

            # محاكاة تأخير الإرسال
            await asyncio.sleep(1)

            logger.info(f"✉️ Email sent to {owner_email}")
            logger.info(f"📄 Email content:\n{email_content}")

            # إرجاع نتيجة العملية
            result = {
                "reminderSent": True,
                "reminderSentAt": datetime.now().isoformat(),
                "recipientEmail": owner_email,
                "recipientName": owner_name,
                "messageType": "checkout_reminder",
            }

            logger.info(f"✅ Reminder sent successfully for job {job.key}")
            return result

        except Exception as e:
            logger.error(f"❌ Error sending reminder: {e}", exc_info=True)
            raise

    logger.info("🚀 Reminder Worker started!")
    logger.info("⏳ Waiting for 'send-reminder' jobs...")

    await worker.work()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("\n👋 Reminder Worker stopped by user")
    except Exception as e:
        logger.error(f"❌ Worker error: {e}", exc_info=True)
