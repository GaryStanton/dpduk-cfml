/**
 * Name: DPD Tracking API
 * Author: Gary Stanton (@SimianE)
 * Description: Wrapper for the DPD Tracking API.
 */
component singleton accessors="true" {

    property name="username" type="string";
    property name="password" type="string";

    property name="sandbox_url"     type="string" default="https://test-apps.geopostuk.com/tracking-core/dpd/parcels/";
    property name="production_url"  type="string" default="https://apps.geopostuk.com/tracking-core/dpd/parcels/";
    property name="api_url"         type="string" default="";


    /**
     * Constructor
     * 
     * @username Your API username
     * @password Your API password
     */
    public tracking function init(
            string username     = "GEOTRACK"
        ,   string password     = "g30tr4ck"
        ,   string environment  = "sandbox"
    ){  
        setUsername(Arguments.username);
        setPassword(Arguments.password);
        setApi_url(Arguments.environment == 'production' ? getProduction_url() : getSandbox_url());

        return this;
    }


    /**
     * Tracks a shipment.
     *
     * @trackingNumbers The consignment number(s) to track. Separate multiple numbers with a comma.
     *
     * @return string|object Response data.
     * @throws Exception
     */
    public function track(
            required string trackingNumbers
    ){

        // Build xml
        Local.xml = '<?xml version="1.0" encoding="UTF-8"?>
            <trackingrequest>
                <user>#getUsername()#</user>
                <password>#getPassword()#</password>
                <trackingnumbers>'
                for (Local.thisTrackingNumber in listToArray(Arguments.trackingNumbers)) {
                    Local.xml &= '
                        <trackingnumber>#Local.thisTrackingNumber#</trackingnumber>'
                }
        Local.xml &= '
                </trackingnumbers>
            </trackingrequest>
        ';

        return makeRequest(
            body = Local.xml
        );
    }


    /**
     * Makes a request to the API. Will return the content from the cfhttp request.
     * @endpoint The request endpoint
     * @body The body of the request
     */
    private function makeRequest(
            required string body
        ,   boolean returnRawXML = false
    ){

        var requestURL  = getApi_url()
        var result      = {};

        cfhttp(
            method  = "POST", 
            charset = "utf-8", 
            url     = requestURL,
            result  = "result"
        ) {
            cfhttpparam(type="xml", name="body", value="#Arguments.body#");
        }

        if (StructKeyExists(result, 'fileContent') && isXML(result.fileContent)) {
            return Arguments.returnRawXML ? result.fileContent : new conversion().ConvertXmlToStruct(result.fileContent, {});
        }
        else {
            return {errors: 'Unable to parse result'};
        }
    }
}