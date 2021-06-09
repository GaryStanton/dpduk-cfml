# DPD UK CFML

DPD UK CFML provides a wrapper for the DPD UK API.
At present, the module only includes access to the tracking API.
Further updates may include the shipping API for label creation.

## Installation
```js
box install dpdukcfml
```

## Examples
Check out the `/examples` folder for an example consignment tracking response.

## Usage
The DPD UK CFML wrapper consists of a two models, one representing DPD UK's Tracking API and the other able to manage connection to the DPD SFTP server to download and process tracking event EDI files.
The wrapper may be used standalone, or as a ColdBox module.


### Standalone
```cfc
	DPDUKTracking = new models.tracking(
			username     = "GEOTRACK"
		,	password     = "g30tr4ck"
		,	environment  = "sandbox"
	);

	DPDUKEvents = new models.events(
			sftpUsername 	= 'sftp.123456'
		,	sftpKeyFile 	= 'path/to/keyfile.ppk'
	);

```

### ColdBox
```cfc
DPDUKTracking 	= getInstance("tracking@DPDUKCFML");
DPDUKEvents 	= getInstance("events@DPDUKCFML");
```
alternatively inject it directly into your handler
```cfc
property name="DPDUKTracking" inject="tracking@DPDUKCFML";
property name="DPDUKEvents" inject="events@DPDUKCFML";
```

When using with ColdBox, you'll want to insert your API authentication details into your module settings:

```cfc
DPDUKCFML = {
		username 		= getSystemSetting("DPDUK_USERNAME", "")
	,	password 		= getSystemSetting("DPDUK_PASSWORD", "")
	,	sftpUsername 	= getSystemSetting("DPDUK_SFTPUSERNAME", "")
	,	sftpKeyfile 	= getSystemSetting("DPDUK_SFTPKEYFILE_PATH", "")
	,	environment 	= 'sandbox'
}
```

### Track a consignment
Tracking a consignment is a simple call to the track function with your consignment number. You may track multiple consignments in a single call by passing multiple consignment numbers separated by a comma.  

```cfc
trackingResponse = DPDUKTracking.track('1234567890');
```

### Retrieve tracking event data
Tracking event files are uploaded to the DPD SFTP server every 20 minutes or so. The events component can be used to list, download and process these files.  

```cfc
fileList = DPDUKEvents.getFileList();
```

```cfc
fileContents = DPDEvents.processRemoteFiles(
		dateRange 			= '2021-01-01,2021-01-31'
	,	removeFromServer 	= false
);
```


## Author
Written by Gary Stanton.  
https://garystanton.co.uk
