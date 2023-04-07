from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup as bs
from selenium import webdriver
import socket
import psutil
import json
import time
import sys


opened_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
LiveStream_URL = "https://www.youtube.com/watch?v=jfKfPfyJRdk"
YouTube_BaseURL = "https://www.youtube.com"
UDP_IP = "127.0.0.1"
UDP_PORT = 4243
chat_src = ""
lastChat = []


def main():
    if len(sys.argv) > 1:
        global LiveStream_URL
        LiveStream_URL = sys.argv[1]

    global chat_src
    user_pids = get_chrome_pids()
    driver_pids = []
    driver = create_driver()

    while True:
        if not chat_src:
            driver.get(LiveStream_URL)
            time.sleep(1)
            content = driver.page_source.encode("utf-8").strip()
            soup = bs(content, "lxml")
            chat_src = soup.find(id="chat").find("iframe").get("src")

            driver_pids = get_chrome_pids(user_pids)
            driver_pids.insert(0, "PIDs")
            send_chat(driver_pids)
        
        get_chat(driver)
        time.sleep(0.5) # Reduce CPU Usage

    driver.quit()


def get_chat(driver):
    SUCCESS = False

    while not SUCCESS:
        try:
            chat_url = "{}{}".format(YouTube_BaseURL, chat_src)
            if driver.current_url != chat_url:
                driver.get(chat_url)
            content = driver.page_source.encode("utf-8").strip()
            soup = bs(content, "lxml")

            usernames = soup.find_all("span", id="author-name")
            messages = soup.find_all("span", id="message")
            global lastChat
            chat = []

            for x in range(len(usernames)-1):
                item = [usernames[x].text, messages[x].text]
                if not item in lastChat:
                    chat.append(item)
            
            if chat:
                lastChat.extend(chat)
                chat.insert(0, "CHAT")
                send_chat(chat)
            
            SUCCESS = True
        
        except Exception as e:
            # print("get chat attempt unsuccessful.")
            # print(e)
            time.sleep(1)
            # print("retrying...")
            continue


def create_driver():
    # Chrome options: https://peter.sh/experiments/chromium-command-line-switches/
    options_ = webdriver.ChromeOptions()
    options_.add_argument('window-size=100,100')
    options_.add_argument('window-position=10000,0')

    return webdriver.Chrome(ChromeDriverManager().install(), options=options_)


def print_list(list):
    for item in list:
        print(item)


def send_chat(chat):
    byte_message = bytes(json.dumps(chat), "utf-8")
    opened_socket.sendto(byte_message, (UDP_IP, UDP_PORT))


def get_chrome_pids(previous=[]):
    pids = []

    for process in psutil.process_iter(["pid", "name"]):
        process = process.info
        if "Google Chrome" in process.get("name"):
            if not process.get("pid") in previous:
                pids.append(process.get("pid")) # int
    
    return pids


if __name__ == "__main__":
    main()
