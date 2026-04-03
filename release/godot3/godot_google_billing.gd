extends Node

var _gbilling : JNISingleton = null

# If true, enables plugin console output for debug information
var _verbose : bool = true

# List of all game products to be queried from the shop
var _gameSkus : Array = [
	"your_persistent_product_1",
	"your_persistent_product_2",
	"your_consumable_product_1",
	"your_consumable_product_2",
	"your_consumable_product_3",
	"your_consumable_product_4",
]

# List of all game products that can be consumed
var _consumableSkus : Array = [
	"your_consumable_product_1",
	"your_consumable_product_2",
	"your_consumable_product_3",
	"your_consumable_product_4",
]

# Dictionary to later store game SKU details
var _gameSkuDetails : Dictionary = {}

# List of persistent purchases unlocked by user (e.g. ad-free option, etc)
var _activePersistentPurcahses : Array = []

# Emitted when products information is successfully loaded
signal sku_details_loaded
# Emitted when user makes a new IAP purchase
signal purchase_made
# Emitted when purchase attempt has failed
signal purchase_error
# Emitted when purchase attempt ended up pending (meaning it will either be successful or cancelled later by the billing)
signal purchase_pending
# Emitted when a new SKU is added to activePersistentPurchases
signal persistent_purchases_updated

# REGION API

# Call this in your entry point (e.g. startup scene)
func initialize() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_gbilling = Engine.get_singleton("GodotGooglePlayBilling")
		_gbilling.connect("connected", self, "_on_connected")
		_gbilling.connect("disconnected", self, "_on_disconnected")
		_gbilling.connect("billing_resume", self, "_on_billing_resume")
		_gbilling.connect("connect_error", self, "_on_connect_error")
		_gbilling.connect("purchases_updated", self, "_on_purchases_updated")
		_gbilling.connect("query_purchases_response", self, "_on_query_purchases_response")
		_gbilling.connect("purchase_error", self, "_on_purchase_error")
		_gbilling.connect("sku_details_query_completed", self, "_on_sku_details_query_completed")
		_gbilling.connect("sku_details_query_error", self, "_on_sku_details_query_error")
		_gbilling.connect("price_change_acknowledged", self, "_on_price_change_acknowledged")
		_gbilling.connect("purchase_acknowledged", self, "_on_purchase_acknowledged")
		_gbilling.connect("purchase_acknowledgement_error", self, "_on_purchase_acknowledgement_error")
		_gbilling.connect("purchase_consumed", self, "_on_purchase_consumed")
		_gbilling.connect("purchase_consumption_error", self, "_on_purchase_consumption_error")
		_gbilling.startConnection()
	else:
		_output("GodotGooglePlayBilling JNI is not present.")

# Starts purchase flow for a specified SKU.
func purchaseSku(skuId:String) -> void:
	var response = _gbilling.purchase(skuId)
	if response.status != OK:
		_output("Purchase error %s: %s" % [response.response_code, response.debug_message])

# Returns product details for specified SKU as Dictionary or NULL if products are not yet loaded. Dictionary structure:
#"sku" : String # Product SKU
#"title" : String # Product title as specified in your Google Play Console
#"description" : String # Product description as specified in your Google Play Console
#"type" : String # Type of the product, can be "inapp" or "subs"
#"icon_url" : String # URL pointing to icon of the product if present; otherwise it's gonna be your app icon
#"price" : String # Humanized final price of the product, e.g. "$1.99"
#"price_currency_code" : String # Currency code, e.g. "USD"
#"price_amount_micros" : int # Integer micro representation of the final price (1.99 USD = 1990000)
#"original_price" : String # Humanized price of the product before discounts or promos, e.g. "$1.99"
#"original_price_amount_micros" : int # Integer micro representation of the original price (1.99 USD = 1990000)
#"subscription_period" : String # Subscription period, specified in ISO 8601 format
#"free_trial_period" : String # Trial period configured in Google Play Console, specified in ISO 8601 format
#"introductory_price" : String # Humazined introductory price of a subscription, e.g. "$1.99"
#"introductory_price_amount_micros" : int # Integer micro representation of the introductory price (1.99 USD = 1990000)
#"introductory_price_cycles" : int # Number of subscription billing periods for which the user will be given the introductory price
#"introductory_price_period" : String # Billing period of the introductory price, specified in ISO 8601 format
func getSkuDetails(sku:String) -> Dictionary:
	return _gameSkuDetails.get(sku)

# Returns true if products information is loaded.
func areSkuDetailsLoaded() -> bool:
	return !_gameSkuDetails.is_empty()

# Returns true if the SKU is consumable.
func isSkuConsumable(sku:String) -> bool:
	return _consumableSkus.has(sku)

# Returns true if a persistent SKU is purchased by the player.
func isPersistentPurchaseActive(sku:String) -> bool:
	return _activePersistentPurcahses.has(sku)

# REGION Customize these

# Fires when a purchase gets acknowledged or consumed; log the purchase with your other SDKs here. Dictionary structure:
#"original_json" : String # String in JSON format that contains details about the purchase order
#"order_id" : String # Unique order identifier for the transaction corresponding to the Google order ID
#"package_name" : String # Package name of the app the purchase was made in
#"purchase_state" : int # UNSPECIFIED_STATE = 0, PURCHASED = 1, PENDING = 2
#"purchase_time" : int # UNIX time in MS
#"purchase_token" : String # Token that uniquely identifies a purchase for a given item and user pair
#"quantity" : int # Quantity of the purchased product; always 1 for SUBS items
#"signature" : String # Signature of the purchase data that was signed with the private key of the developer
#"developer_payload" # Payload specified when the purchase was acknowledged or consumed
#"sku" : String # Product SKU
#"is_acknowledged" : bool # Whether the purchase has been acknowledged
#"is_auto_renewing" : bool # Whether the subscription renews automatically
func _logPurchase(purchase:Dictionary) -> void:
	_output("Log your purchase here. Purchase contents: %s" % purchase)

# Plugin logger. Customize as you want.
func _output(message:String) -> void:
	if !_verbose:
		return
	print("%s: %s" % [name, message])

# Called when a fresh purchase was made or a hanging purchase was detected and processed only now.
# Give player their rewards here.
func _givePurchaseToPlayer(sku:String) -> void:
	_output("SKU %s has just been purchased. Give it to the player in _givePurchaseToPlayer(sku)." % sku)

# REGION Internal

# Retrieves information about available IAP products.
func _queryGameSkus() -> void:
	_gbilling.querySkuDetails(_gameSkus, "inapp")

# Retrieves information about purchases made by the player.
func _queryPlayerPurchases() -> void:
	_gbilling.queryPurchases("inapp") # Use "subs" for subscriptions.

# Acknowledges or consumes a purchase and calls _givePurchaseToPlayer() to handle in-game logic
func _acknowledgePurchase(purchase:Dictionary) -> void:
	_output("Purchase %s has not been acknowledged. Giving product to player." % purchase.sku)
	_givePurchaseToPlayer(purchase.sku)
	if isSkuConsumable(purchase.sku):
		_output("Purchase %s is consumable. Trying to consume..." % purchase.sku)
		_gbilling.consumePurchase(purchase.purchase_token)
	else:
		_output("Purchase %s is not consumable. Trying to acknowledge..." % purchase.sku)
		_gbilling.acknowledgePurchase(purchase.purchase_token)

func _checkIfPurchaseIsPersistent(sku:String) -> void:
	if !isSkuConsumable(sku):
		if !_activePersistentPurcahses.has(sku):
			_activePersistentPurcahses.push_back(sku)
			_output("Player has %s consistent IAP purchased." % sku)
			emit_signal("persistent_purchases_updated")

func _outputPurchase(purchase:Dictionary) -> void:
	_output("\n")
	_output("#### Purchase Begin ####")
	for elem in purchase:
		if elem == "original_json":
			_output("original_json = {")
			var test_json_conv = JSON.new()
			test_json_conv.parse(purchase[elem])
			var dict : Dictionary = test_json_conv.get_data()
			for key in dict:
				_output("\t%s : %s" % [key, dict[key]])
			_output("}")
		else:
			_output("%s: %s" % [elem, purchase[elem]])
	_output("##### Purchase End #####\n")

# REGION Callbacks

func _on_connected() -> void:
	_output("GodotGooglePlayBilling connected successfully.")
	_queryGameSkus()

func _on_disconnected() -> void:
	_output("GodotGooglePlayBilling disconnected. Will try to reconnect in 10s...")
	await get_tree().create_timer(10).timeout
	_gbilling.startConnection()

func _on_billing_resume() -> void:
	pass

# Response ID (int), Debug message (string).
func _on_connect_error(code:int, message:String) -> void:
	_output("Connect error, code %s, message: %s" % [code, message])

# Fires when an IAP was just commited by the user, "purchases" is an Array of Dictionaries
func _on_purchases_updated(purchases:Array) -> void:
	_output("Purchases updated.")
	# Debug information
	if _verbose:
		for purchase in purchases:
			_outputPurchase(purchase)
	for purchase in purchases:
		# UNSPECIFIED_STATE = 0 PURCHASED = 1 PENDING = 2
		if purchase.purchase_state == 1:
			if not purchase.is_acknowledged:
				_acknowledgePurchase(purchase)
				_logPurchase(purchase)
				emit_signal("purchase_made")
			# Index persistent SKUs as active
			_checkIfPurchaseIsPersistent(purchase.sku)
		if purchase.purchase_state == 2:
			emit_signal("purchase_pending")

# Fires when result of _queryPlayerPurchases() was obtained (usually on game startup), purchases is Dictionary
func _on_query_purchases_response(query_result:Dictionary) -> void:
	_output("Query purchases response status: %s" % query_result.status)
	# Debug information
	if _verbose:
		for purchase in query_result.purchases:
			_outputPurchase(purchase)
	if query_result.status == OK:
		for purchase in query_result.purchases:
			if not purchase.is_acknowledged:
				_acknowledgePurchase(purchase)
				_logPurchase(purchase)
				emit_signal("purchase_made")
			# If we have an acknowledged consumable purchase still hanging in Purchases, this must be a promo code
			elif isSkuConsumable(purchase.sku):
				_acknowledgePurchase(purchase)
			# Index persistent SKUs as active
			_checkIfPurchaseIsPersistent(purchase.sku)
	else:
		_output("queryPurchases failed, response code: %s debug message: %s" % [query_result.response_code, query_result.debug_message])

# Response ID (int), Debug message (string).
# See https://developer.android.com/reference/com/android/billingclient/api/BillingClient.BillingResponseCode
func _on_purchase_error(code:int, message:String) -> void:
	match code:
		-1, 2, 3, 5, 6, 4, 12:
			emit_signal("purchase_error")
	_output("Purchase error %d: %s" % [code, message])

# SKUs (Array of Dictionaries).
func _on_sku_details_query_completed(sku_details:Array) -> void:
	for dict in sku_details:
		_gameSkuDetails[dict.sku] = dict
		if _verbose:
			_output(str(dict))
	_output("SKU details queried. SKUs: %s" % [sku_details.size()])
	emit_signal("sku_details_loaded")
	_queryPlayerPurchases()

# Response ID (int), Debug message (string), Queried SKUs (string[]).
func _on_sku_details_query_error(code:int, message:String, queried_skus:Array):
	_output("SKU details query error %d: %s, %s" % [code, message, queried_skus])
	_output("Retrying query in 5 seconds")
	await get_tree().create_timer(5.0).timeout
	_queryGameSkus()

# Response ID (int)
func _on_price_change_acknowledged(code:int) -> void:
	_output("Price change acknowledged, code %s" % code)

# Purchase token (string).
func _on_purchase_acknowledged(purchase_token:String) -> void:
	_output("Purchase acknowledged: %s" % purchase_token)

# Response ID (int), Debug message (string), Purchase token (string).
func _on_purchase_acknowledgement_error(code:int, message:String, token:String) -> void:
	_output("Purchase acknowledgement error %d: %s, %s" % [code, message, token])

# Purchase token (string).
func _on_purchase_consumed(purchase_token:String) -> void:
	_output("Purchase consumed successfully: %s" % purchase_token)

# Response ID (int), Debug message (string), Purchase token (string).
func _on_purchase_consumption_error(code:int, message:String, purchase_token:String) -> void:
	_output("Purchase consumption error %d: %s, purchase token: %s" % [code, message, purchase_token])
