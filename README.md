# DPD UK CFML

DPD UK CFML provides a wrapper for the DPD UK API.
At present, the module only includes access to the tracking API.
Further updates may include the shipping API for label creation.

## Installation
```js
box install dpduk-cfml
```

## Examples
Check out the `/examples` folder for an example consignment tracking response.

## Usage
The DPD UK CFML wrapper consists of a single model representing DPD UK's Tracking API. 
The wrapper may be used standalone, or as a ColdBox module.


### Standalone
```cfc
	DPDUKTracking = new models.tracking(
		username     = "GEOTRACK"
		password     = "g30tr4ck"
		environment  = "sandbox"
	);
```

### ColdBox
```cfc
DPDUKTracking = getInstance("tracking@DPDUKCFML");
```
alternatively inject it directly into your handler
```cfc
property name="DPDUKTracking" inject="tracking@DPDUKCFML";
```

When using with ColdBox, you'll want to insert your API authentication details into your module settings:

```cfc
DPDUKCFML = {
		DPDUKUsername = getSystemSetting("DPDUK_USERNAME", "")
	,	DPDUKPassword = getSystemSetting("DPDUK_PASSWORD", "")
	,	environment = 'sandbox'
}
```

### Track a consignment
Tracking a consignment is a simple call to the track function with your consignment number. You may track multiple consignments in a single call by passing multiple consignment numbers separated by a comma.

```cfc
	trackingResponse = DPDUKTracking.track('1234567890');
```

## Author
Written by Gary Stanton.  
https://garystanton.co.uk
