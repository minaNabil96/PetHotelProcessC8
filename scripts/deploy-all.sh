#!/bin/bash

# ==================================
# Pet Hotel - Complete Deployment Script
# ==================================

set -e

echo "🐾 ============================================"
echo "🐾 Pet Hotel Camunda 8 - Full Deployment"
echo "🐾 ============================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if zbctl is installed
if ! command -v zbctl &> /dev/null; then
    echo -e "${RED}❌ zbctl is not installed!${NC}"
    echo "Install it with: npm install -g zbctl"
    exit 1
fi

# Environment selection
echo -e "${BLUE}Select environment:${NC}"
echo "1) Local Docker (localhost:26500)"
echo "2) Camunda 8 SaaS"
read -p "Choice: " ENV_CHOICE

if [ "$ENV_CHOICE" == "1" ]; then
    echo -e "${GREEN}✅ Using Local Docker${NC}"
    ZEEBE_ADDRESS="localhost:26500"
    DEPLOY_CMD="zbctl --address $ZEEBE_ADDRESS --insecure"
elif [ "$ENV_CHOICE" == "2" ]; then
    echo -e "${GREEN}✅ Using Camunda 8 SaaS${NC}"
    
    if [ -z "$ZEEBE_ADDRESS" ]; then
        read -p "Enter ZEEBE_ADDRESS: " ZEEBE_ADDRESS
    fi
    if [ -z "$ZEEBE_CLIENT_ID" ]; then
        read -p "Enter ZEEBE_CLIENT_ID: " ZEEBE_CLIENT_ID
    fi
    if [ -z "$ZEEBE_CLIENT_SECRET" ]; then
        read -sp "Enter ZEEBE_CLIENT_SECRET: " ZEEBE_CLIENT_SECRET
        echo ""
    fi
    
    export ZEEBE_ADDRESS
    export ZEEBE_CLIENT_ID
    export ZEEBE_CLIENT_SECRET
    
    DEPLOY_CMD="zbctl"
else
    echo -e "${RED}❌ Invalid choice${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Checking connection...${NC}"
$DEPLOY_CMD status || { echo -e "${RED}❌ Cannot connect to Zeebe${NC}"; exit 1; }

echo ""
echo -e "${GREEN}✅ Connection successful!${NC}"
echo ""

# Deploy Forms
echo -e "${YELLOW}📝 Deploying Forms (16 files)...${NC}"
FORMS=(
    "forms/01_BookingForm.form"
    "forms/02_CheckInForm.form"
    "forms/03_VetCheckForm.form"
    "forms/04_RoomAssignmentForm.form"
    "forms/05_FeedingForm.form"
    "forms/06_WalkForm.form"
    "forms/07_HealthCheckForm.form"
    "forms/08_MedicationForm.form"
    "forms/09_OwnerUpdateForm.form"
    "forms/10_DailyActivityForm.form"
    "forms/11_DepartureForm.form"
    "forms/12_FinalReportForm.form"
    "forms/13_CheckoutForm.form"
    "forms/14_FeedbackForm.form"
    "forms/15_CleaningForm.form"
    "forms/16_EmergencyForm.form"
)

for form in "${FORMS[@]}"; do
    if [ -f "$form" ]; then
        echo "  ➤ $(basename $form)"
        $DEPLOY_CMD deploy "$form" > /dev/null 2>&1 || echo -e "    ${RED}✗ Failed${NC}"
    else
        echo -e "  ${RED}✗ Missing: $form${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🎯 Deploying DMN Decisions (2 files)...${NC}"
DMN_FILES=(
    "dmn/vaccination_check.dmn"
    "dmn/pet_compatibility_check.dmn"
)

for dmn in "${DMN_FILES[@]}"; do
    if [ -f "$dmn" ]; then
        echo "  ➤ $(basename $dmn)"
        $DEPLOY_CMD deploy "$dmn" > /dev/null 2>&1 || echo -e "    ${RED}✗ Failed${NC}"
    else
        echo -e "  ${RED}✗ Missing: $dmn${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🔄 Deploying BPMN Process...${NC}"
if [ -f "bpmn/PetHotelProcess_v3.bpmn" ]; then
    echo "  ➤ PetHotelProcess_v3.bpmn"
    $DEPLOY_CMD deploy "bpmn/PetHotelProcess_v3.bpmn" || { echo -e "${RED}❌ BPMN deployment failed${NC}"; exit 1; }
else
    echo -e "${RED}❌ BPMN file not found!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ ============================================${NC}"
echo -e "${GREEN}✅ All resources deployed successfully!${NC}"
echo -e "${GREEN}✅ ============================================${NC}"
echo ""

# Ask if user wants to create a test instance
read -p "Create a test instance? (y/n): " CREATE_INSTANCE

if [ "$CREATE_INSTANCE" == "y" ] || [ "$CREATE_INSTANCE" == "Y" ]; then
    echo ""
    echo -e "${BLUE}🧪 Creating test instance...${NC}"
    
    TEST_VARS='{
      "clientName": "Иван Тестов",
      "clientContact": "+79161234567",
      "clientEmail": "test@pethotel.ru",
      "emergencyContact": "+79167654321",
      "petName": "Рекс",
      "petType": "dog",
      "petBreed": "Лабрадор",
      "petAge": 3,
      "temperament": "Спокойный",
      "socialLevel": "Высокий",
      "lastVaccinationDate": "2024-01-15",
      "vaccinationType": "Комплексная",
      "vetContact": "+79161111111",
      "allergies": "Нет",
      "medicalNotes": "",
      "requiresMedication": false,
      "feedingSchedule": "twice",
      "foodType": "hotel",
      "checkInDate": "2024-12-20",
      "checkOutDate": "2024-12-25",
      "specialRequests": "Любит играть с мячом"
    }'
    
    $DEPLOY_CMD create instance PetHotelProcess_v3 --variables "$TEST_VARS"
    
    echo ""
    echo -e "${GREEN}✅ Test instance created!${NC}"
fi

echo ""
echo -e "${BLUE}🌐 Access URLs:${NC}"
if [ "$ENV_CHOICE" == "1" ]; then
    echo "  • Tasklist: http://localhost:8082"
    echo "  • Operate:  http://localhost:8081"
else
    echo "  • Tasklist: https://[your-region].tasklist.camunda.io"
    echo "  • Operate:  https://[your-region].operate.camunda.io"
fi

echo ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"