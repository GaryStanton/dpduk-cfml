component{
	this.name = "dpd-uk-cfml-examples-" & hash(getCurrentTemplatePath());

	/**
	 * onError
	 */
   void function onError(struct exception, string eventName) {
       writeDump(Arguments);
       abort;
   }
}