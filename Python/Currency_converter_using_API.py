# import the package requests to use the API
import requests
import pandas as pd
import numpy as np
print("Currency Conversion")
print("Take the help of the below table for the conversion:")
d = {"AUD":"Australian Dollar","BGN":"Bulgarian Lev","BRL":"Brazilian Real","CAD":"Canadian Dollar","CHF":"Swiss Franc","CNY":"Chinese Renminbi Yuan","CZK":"Czech Koruna","DKK":"Danish Krone","EUR":"Euro","GBP":"British Pound","HKD":"Hong Kong Dollar","HUF":"Hungarian Forint","IDR":"Indonesian Rupiah","ILS":"Israeli New Sheqel","INR":"Indian Rupee","ISK":"Icelandic Króna","JPY":"Japanese Yen","KRW":"South Korean Won","MXN":"Mexican Peso","MYR":"Malaysian Ringgit","NOK":"Norwegian Krone","NZD":"New Zealand Dollar","PHP":"Philippine Peso","PLN":"Polish Złoty","RON":"Romanian Leu","SEK":"Swedish Krona","SGD":"Singapore Dollar","THB":"Thai Baht","TRY":"Turkish Lira","USD":"United States Dollar","ZAR":"South African Rand"}

data = [(key, values) for key, values in d.items()]
d1 = pd.DataFrame(data, columns=['Country', 'Currency'])
print(d1)

# taking input from the user
currency = input('Enter the current you want to convert')
currency = str(currency).upper()

converted_currency = input('Enter the current you want to convert')
converted_currency = str(converted_currency).upper()

amount = float(input('Enter the amount to convert:'))

# Using frankfurter API for the currency conversion (any other API can also be used)
response = requests.get(f"https://api.frankfurter.app/latest?amount={amount}&from={currency}&to={converted_currency}")

# final output
print(f"{amount} {currency} = {response.json()['rates'][converted_currency]} {converted_currency}")
