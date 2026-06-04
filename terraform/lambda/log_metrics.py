def handler(event, context):
    print("📈 Logging metrics to MLflow...")
    # In real life — you would make a request to the MLflow API here
    return {"status": "logged"}
