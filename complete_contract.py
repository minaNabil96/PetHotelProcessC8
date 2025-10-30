import asyncio
from datetime import datetime
from pyzeebe import ZeebeWorker, Job, create_insecure_channel

async def main():
    # إنشاء Worker
    channel = create_insecure_channel(grpc_address="localhost:26500")
    worker = ZeebeWorker(channel)

    @worker.task(task_type="generate-contract")
    async def generate_contract(job: Job):
        try:
            print(f"🔄 Generating contract...")
            print(f"Job variables: {job.variables}")
            
            # منطق توليد العقد
            contract_data = {
                "contractId": f"CONTRACT-{datetime.now().strftime('%Y%m%d%H%M%S')}",
                "generatedAt": datetime.now().isoformat(),
                "status": "created"
            }
            
            print(f"✅ Contract generated: {contract_data}")
            return contract_data
            
        except Exception as e:
            print(f"❌ Error generating contract: {e}")
            raise

    print("🚀 Worker started and waiting for jobs...")
    await worker.work()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⏹️  Worker stopped")