# ORKA — Architecture

## Roles
- Customer : Scan nutrition, Nora chatbot, food map, history
- Restaurant : Full scan, inventory, HACCP alerts, waste, Chef AI
- Hotel : Contamination/freshness scan, HACCP, Sage

## AI Pipeline
Photo -> Cloudinary -> Gemini API (freshness, waste, compost CO2, nutrition, allergens) -> YOLO v8 (contamination) -> Firestore

## Firestore Schema
- users/{uid} : role, entityId, allergens, dietaryOptions
- restaurants/{id}/scans/{scanId}
- hotels/{id}/scans/{scanId}
- chatMessages/{uid}/nora|chefai|sage/{messageId}
- nutrientLogs/{uid}/{date}

## AI Chatbots
- Nora : AI Nutritionist (customer health and nutrition)
- Chef AI : Kitchen assistant (HACCP, waste, FIFO)
- Sage : Hotel sustainability consultant (CO2, waste, compliance)
