def handler(event, context):
    print("✅ Validating input data...")
    # In real life — schema validation or CSV checking would happen here
    return {"status": "valid"}
