import json
import requests

MIN_PRICE=5000
#   4 hour minimum
MIN_TIME=4
#   $500 per hour above 4
RATE=500
#   Not to exceed 8 total hours
MAX_TIME=8

def get_price_conversion():
    api_url = 'https://api.coinmarketcap.com/v1/ticker/ethereum/?convert=USD'
    headers = {'Content-Type': 'application/json'}

    response = requests.get(api_url, headers=headers)

    if response.status_code == 200:
        results = json.loads(response.content.decode('utf-8'))
        eth_price = float(results[0]['price_usd']) # 1 ETH = X dollars
        btc_price = eth_price/float(results[0]['price_btc']) # 1 BTC = X dollars
        return eth_price, btc_price
    else:
        return None

if __name__ == '__main__':
    usd_eth_rate, usd_btc_rate = get_price_conversion()
    minimum_rate = "${0:0.2f} minimum ({1:0.1f} ETH, {2:0.3f} BTC)".\
            format(*[MIN_PRICE/conv for conv in [1, usd_eth_rate, usd_btc_rate]])
    hourly_rate = "${0:0.2f} per hour ({1:0.1f} ETH, {2:0.3f} BTC)".\
            format(*[RATE/conv for conv in [1, usd_eth_rate, usd_btc_rate]])
    print("My Rates are:")
    print("  {}, for {} hours".format(minimum_rate, MIN_TIME))
    print("  {}, up to {} hours total".format(hourly_rate, MAX_TIME))
