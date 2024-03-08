from playwright.sync_api import sync_playwright
import mysql.connector

def main():
    with sync_playwright() as p:
        ### scrape data
        browser = p.chromium.launch(headless=False, executable_path="C:/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe")
        
        page = browser.new_page()
        
        page.goto("https://coinmarketcap.com/")
        
        # scrolling down the webpage in order to get the top 100 crypto currencies in the page
        for i in range(5):
            page.mouse.wheel(0, 2000)
            page.wait_for_timeout(1000)
            # this scrolls down the mouse by 2000 and pauses for 1 second in order to let the page load in between the scrolls
        
        # inspect the site, and see the class and divisions that the data belongs to
        # we are looking for the table that contains the names of the crypto currencies. In the website, it is inside a table, then each "tr" has the invidual rows of crypto currencies that stores the individual values with respect to the columns in "td" field
        
        # extracting the "tr" fields from the table
        trs_xpath = "//table[@class='sc-14cb040a-3 dsflYb cmc-table  ']/tbody/tr"
        
        # query_selector_all gives us all the elements that satisfy the condition
        trs_list = page.query_selector_all(trs_xpath)
        print(len(trs_list)) # should print 100 i.e., as trs_list contains all 100 items that we need
 
        # master list contains all of the product
        master_list = []
        
        # Looping through the "tr" part of the table (which is individual rows) to get to the "td" field
        for tr in trs_list:
            coin_dict = {}
            tds = tr.query_selector_all('//td')
            
            # storing the 1st index of tds element into the key field of coin_dict dictionary, and every 100 elements of the list will have their own coin_dict with various keys as columns, and their respective values as data.
            coin_dict['id'] = tds[1].inner_text()
            coin_dict['Name'] = tds[2].query_selector("//p[@color='text']").inner_text()   
            coin_dict['Symbol'] = tds[2].query_selector("//p[@color='text3']").inner_text()
            
            # eliminating the dollar sign in front of the price and replacing it with nothing
            coin_dict['Price'] = float(tds[3].inner_text().replace('$', '').replace(',', ''))
            coin_dict['Market_cap_USD'] = int(tds[7].inner_text().replace('$', '').replace(',',''))
            
            coin_dict['Volume_24h_USD'] = int(tds[8].query_selector("//p[@color='text']").inner_text().replace('$','').replace(',', ''))
            
            # appending data obtained from the list into the dictionary
            master_list.append(coin_dict)
        
        # saving the data in form of tuples
        # typle (id, name, symbol, ....)
        list_of_tuples = [tuple(dic.values()) for dic in master_list]
        
        ### save data in sql database
        
        # connect to the database
        mysql_conn = mysql.connector.connect(host='localhost', user='root', password='shweta', database='crypto')
        
        if mysql_conn.is_connected():
            print("Connected to MySQL database successfully")
        else:
            print("Failed to connect to MySQL database")

        # creating cursor in order to write queries in the server
        cursor = mysql_conn.cursor()
        
        mySql_insert_query = "INSERT INTO crypto (id, name, symbol, price_usd, market_cap_usd, volume_24h_usd) VALUES (%s, %s, %s, %s, %s, %s)"        
        cursor.executemany(mySql_insert_query, list_of_tuples)        
        
        # # commiting the changes
        mysql_conn.commit()
        print(cursor.rowcount, "Record inserted successfully into Laptop table")
        print("Connection successful.")
        cursor.close()
    
        mysql_conn.close()
                
        browser.close()

if __name__ == "__main__":
    main()
