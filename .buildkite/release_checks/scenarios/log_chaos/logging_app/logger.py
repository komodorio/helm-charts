import time
import logging
import random
import string

logging.basicConfig(level=logging.INFO)


def get_words_from_file(filename):
    with open(filename, 'r') as file:
        words = file.read().splitlines()
    return words


words = get_words_from_file('words.txt')


def generate_random_string(length):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))


def generate_log_message(num_of_lines):
    final_message = []
    for _ in range(num_of_lines):
        num_words = random.randint(3, 50)
        message_words = [random.choice(words) for _ in range(num_words)]
        final_message.append(' '.join(message_words))
    return '\n'.join(final_message)


while True:
    # 90% of the time, generate 1 line, otherwise generate between 2 to 10 lines
    num_lines = 1 if random.random() < 0.9 else random.randint(3, 10)
    logging.info(generate_log_message(num_lines))
    time.sleep(random.uniform(0.01, 0.5))  # Random sleep time between log bursts
