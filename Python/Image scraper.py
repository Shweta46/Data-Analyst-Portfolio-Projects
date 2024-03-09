# get this from webdriver website
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
import time
import requests

# opens browser
driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()))

# goes to this url
URL = 'https://unsplash.com/'

# telling the driver to get the URL
driver.get(URL)

# scrolling down to get more images from the website
height = 0
for i in range(15):
    height = height + 500
    driver.execute_script(f"window.scrollTo(0, {height});")
    time.sleep(1)

### Get URLs of images you want to scrape

# time.sleep(10)

# to get all the images in the page by using inspect seeing which class all the images belong to
image_tags = driver.find_elements(By.XPATH, "//img[@class='tB6UZ a5VGX']")
print(len(image_tags))

# using list comprehension to get te
image_urls = [img.get_attribute('src') for img in image_tags if not img.get_attribute('src').endswith('4.0.3')]

### download the images

# stream = True means that we are keeping the connection alive
for index, url in enumerate(image_urls[:10]):
    response = requests.get(url, stream=True)
    
    # requests is much faster than selinium

    # wb: write in binary as images are treated as binary in Python
    with open(f'image-{index+1}.jpg', 'wb') as f:
        for chunk in response.iter_content(chunk_size=128):
            f.write(chunk) 
     
driver.close()
