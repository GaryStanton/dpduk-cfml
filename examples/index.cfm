<!doctype html>

<cfscript>
	if (StructKeyExists(Form, 'trackingnumber') && Len(Form.trackingnumber)) {
		DPDTracking = new models.tracking(
			environment = 'sandbox'
		);

		track = DPDTracking.track(Form.trackingnumber);
	}
</cfscript>

<html lang="en">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
		<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
		<title>DPD CFML examples</title>
	</head>

	<body>
		<div class="container">
			<h1>DPD CFML examples</h1>
			<hr>

			<div class="row">
				<div class="col-sm-6">
					<div class="mr-4">
						<h2>Track shipment</h2>
						<form method="POST">
							<div class="input-group">
								<input type="text" required="true" class="form-control" id="trackingnumber" name="trackingnumber" aria-describedby="trackingnumber" placeholder="Enter a tracking number">
								<div class="input-group-append">
									<button type="submit" class="btn btn-primary" type="button" name="action" value="tracking">Query DPD tracking API</button>
								</div>
								<small id="trackingnumberHelp" class="form-text text-muted">When in sandbox mode, you may use testing tracking numbers as follows: <br />1355390751, 1189449656, 1355411961, 1355412106</small>
							</div>
						</form>
					</div>
				</div>
			</div>

			<cfif structKeyExists(Variables, 'track')>
				<hr />
				<cfdump var="#track#">
			</cfif>
		</div>
	</body>
</html>