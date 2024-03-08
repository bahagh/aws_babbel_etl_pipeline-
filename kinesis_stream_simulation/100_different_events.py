import random

# Defining parts for the event type
parts = [["account", "lesson", "payment", "user", "order", "product"],
         ["created", "started", "completed", "updated", "deleted", "processed"],
         ["success", "failure", "pending", "timeout", "error", "cancel"]]

event_types = set()

# Generate 100 unique event types
while len(event_types) < 100:
    event_parts = []
    for part in parts:
        if random.choice([True, False]):  # Randomly decide to use this part
            event_parts.append(random.choice(part))
    event = ":".join(event_parts)
    event_types.add(event)
B=[]
# Printing the generated event types
for event in event_types:
    B.append(str(event))

# then copy pasted the generated events to the KDG template
B[1:]