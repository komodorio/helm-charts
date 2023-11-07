import time
import os

leak = []
interval_seconds = 10


def simulate_leak():
    """Simulate a memory leak by allocating 1 MB of memory every 10 second
        In case the memory limit is set to 50 MB, the pod will be OOMKilled after 500 seconds (8.3 minutes)
    """
    mem_limit = int(os.environ.get("MEMORY_LIMIT", "0"))
    while True:
        leak.append(" " * 10**6)  # Allocate 1 MB of memory every second
        print(f"Allocated {len(leak)} MB of memory")
        if mem_limit:
            print("Will rach memory limit in {} seconds".format((mem_limit - len(leak)) * interval_seconds))
        time.sleep(interval_seconds)


if __name__ == "__main__":
    simulate_leak()
