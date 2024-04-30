from plyer import notification
import time
def send_notification():
    time.sleep(1)
    main_title = "HEY!"
    notification_message = "Your tasks are waiting in the bucket!"
    notification.notify(
    title = main_title,
    message = notification_message,
    timeout = 1  #time to display the message
    )

if __name__ == "__main__":
    send_notification()
