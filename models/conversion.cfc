<cfcomponent>

<!--- 
This function converts XML variables into Coldfusion Structures. It also
returns the attributes for each XML node.
https://www.anujgakhar.com/2007/11/05/coldfusion-xml-to-struct/
--->
	<cffunction name="ConvertXmlToStruct" access="public" returntype="struct" output="false"
					hint="Parse raw XML response body into ColdFusion structs and arrays and return it.">
		<cfargument name="xmlNode" type="string" required="true" />
		<cfargument name="str" type="struct" required="true" />
		<!---Setup local variables for recurse: --->
		<cfset var i = 0 />
		<cfset var axml = arguments.xmlNode />
		<cfset var astr = arguments.str />
		<cfset var n = "" />
		<cfset var tmpContainer = "" />
		
		<cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
		<cfset axml = axml[1] />
		<!--- For each children of context node: --->
		<cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
			<!--- Read XML node name without namespace: --->
			<cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
			<!--- If key with that name exists within output struct ... --->
			<cfif structKeyExists(astr, n)>
				<!--- ... and is not an array... --->
				<cfif not isArray(astr[n])>
					<!--- ... get this item into temp variable, ... --->
					<cfset tmpContainer = astr[n] />
					<!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
					<cfset astr[n] = arrayNew(1) />
					<!--- ... and reassing temp item as a first element of new array: --->
					<cfset astr[n][1] = tmpContainer />
				<cfelse>
					<!--- Item is already an array: --->
					
				</cfif>
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
						<!--- recurse call: get complex item: --->
						<cfset astr[n][arrayLen(astr[n])+1] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
					<cfelse>
						<!--- else: assign node value as last element of array: --->
						<cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
				</cfif>
			<cfelse>
				<!---
					This is not a struct. This may be first tag with some name.
					This may also be one and only tag with this name.
				--->
				<!---
						If context child node has child nodes (which means it will be complex type): --->
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
					<!--- recurse call: get complex item: --->
					<cfset astr[n] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
				<cfelse>
					<!--- else: assign node value as last element of array: --->
					<!--- if there are any attributes on this element--->
					<cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
						<!--- assign the text --->
						<cfset astr[n] = axml.XmlChildren[i].XmlText />
							<!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
						 <cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
						 <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
							 <cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
								 <!--- remove any namespace attributes--->
								<cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
							 </cfif>
						 </cfloop>
						 <!--- if there are any atributes left, append them to the response--->
						 <cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
							 <cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
						</cfif>
					<cfelse>
						 <cfset astr[n] = axml.XmlChildren[i].XmlText />
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- return struct: --->
		<cfreturn astr />
	</cffunction>


<!--- 
	Ben Nadel's function to convert CSV data to a query object: 
	https://gist.github.com/bennadel/9752401
--->
	<cffunction
		name="CSVToQuery"
		access="public"
		returntype="query"
		output="false"
		hint="Converts the given CSV string to a query.">

		<!--- Define arguments. --->
		<cfargument
			name="CSV"
			type="string"
			required="true"
			hint="This is the CSV string that will be manipulated."
			/>

		<cfargument
			name="Delimiter"
			type="string"
			required="false"
			default=","
			hint="This is the delimiter that will separate the fields within the CSV value."
			/>

		<cfargument
			name="Qualifier"
			type="string"
			required="false"
			default=""""
			hint="This is the qualifier that will wrap around fields that have special characters embeded."
			/>


		<!--- Define the local scope. --->
		<cfset var LOCAL = StructNew() />


		<!---
			When accepting delimiters, we only want to use the first
			character that we were passed. This is different than
			standard ColdFusion, but I am trying to make this as
			easy as possible.
		--->
		<cfset ARGUMENTS.Delimiter = Left( ARGUMENTS.Delimiter, 1 ) />

		<!---
			When accepting the qualifier, we only want to accept the
			first character returned. Is is possible that there is
			no qualifier being used. In that case, we can just store
			the empty string (leave as-is).
		--->
		<cfif Len( ARGUMENTS.Qualifier )>

			<cfset ARGUMENTS.Qualifier = Left( ARGUMENTS.Qualifier, 1 ) />

		</cfif>


		<!---
			Set a variable to handle the new line. This will be the
			character that acts as the record delimiter.
		--->
		<cfset LOCAL.LineDelimiter = Chr( 10 ) />


		<!---
			We want to standardize the line breaks in our CSV value.
			A "line break" might be a return followed by a feed or
			just a line feed. We want to standardize it so that it
			is just a line feed. That way, it is easy to check
			for later (and it is a single character which makes our
			life 1000 times nicer).
		--->
		<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll(
			"\r?\n",
			LOCAL.LineDelimiter
			) />


		<!---
			Let's get an array of delimiters. We will need this when
			we are going throuth the tokens and building up field
			values. To do this, we are going to strip out all
			characters that are NOT delimiters and then get the
			character array of the string. This should put each
			delimiter at it's own index.
		--->
		<cfset LOCAL.Delimiters = ARGUMENTS.CSV.ReplaceAll(
			"[^\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]+",
			""
			)

			<!---
				Get character array of delimiters. This will put
				each found delimiter in its own index (that should
				correspond to the tokens).
			--->
			.ToCharArray()
			/>


		<!---
			Add a blank space to the beginning of every theoretical
			field. This will help in make sure that ColdFusion /
			Java does not skip over any fields simply because they
			do not have a value. We just have to be sure to strip
			out this space later on.

			First, add a space to the beginning of the string.
		--->
		<cfset ARGUMENTS.CSV = (" " & ARGUMENTS.CSV) />

		<!--- Now add the space to each field. --->
		<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll(
			"([\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1})",
			"$1 "
			) />


		<!---
			Break the CSV value up into raw tokens. Going forward,
			some of these tokens may be merged, but doing it this
			way will help us iterate over them. When splitting the
			string, add a space to each token first to ensure that
			the split works properly.

			BE CAREFUL! Splitting a string into an array using the
			Java String::Split method does not create a COLDFUSION
			ARRAY. You cannot alter this array once it has been
			created. It can merely be referenced (read only).

			We are splitting the CSV value based on the BOTH the
			field delimiter and the line delimiter. We will handle
			this later as we build values (this is why we created
			the array of delimiters above).
		--->
		<cfset LOCAL.Tokens = ARGUMENTS.CSV.Split(
			"[\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1}"
			) />


		<!---
			Set up the default records array. This will be a full
			array of arrays, but for now, just create the parent
			array with no indexes.
		--->
		<cfset LOCAL.Rows = ArrayNew( 1 ) />

		<!---
			Create a new active row. Even if we don't end up adding
			any values to this row, it is going to make our lives
			more smiple to have it in existence.
		--->
		<cfset ArrayAppend(
			LOCAL.Rows,
			ArrayNew( 1 )
			) />

		<!---
			Set up the row index. THis is the row to which we are
			actively adding value.
		--->
		<cfset LOCAL.RowIndex = 1 />


		<!---
			Set the default flag for wether or not we are in the
			middle of building a value across raw tokens.
		--->
		<cfset LOCAL.IsInValue = false />


		<!---
			Loop over the raw tokens to start building values. We
			have no sense of any row delimiters yet. Those will
			have to be checked for as we are building up each value.
		--->
		<cfloop
			index="LOCAL.TokenIndex"
			from="1"
			to="#ArrayLen( LOCAL.Tokens )#"
			step="1">


			<!---
				Get the current field index. This is the current
				index of the array to which we might be appending
				values (for a multi-token value).
			--->
			<cfset LOCAL.FieldIndex = ArrayLen(
				LOCAL.Rows[ LOCAL.RowIndex ]
				) />

			<!---
				Get the next token. Trim off the first character
				which is the empty string that we added to ensure
				proper splitting.
			--->
			<cfset LOCAL.Token = LOCAL.Tokens[ LOCAL.TokenIndex ].ReplaceFirst(
				"^.{1}",
				""
				) />


			<!---
				Check to see if we have a field qualifier. If we do,
				then we might have to build the value across
				multiple fields. If we do not, then the raw tokens
				should line up perfectly with the real tokens.
			--->
			<cfif Len( ARGUMENTS.Qualifier )>


				<!---
					Check to see if we are currently building a
					field value that has been split up among
					different delimiters.
				--->
				<cfif LOCAL.IsInValue>


					<!---
						ASSERT: Since we are in the middle of
						building up a value across tokens, we can
						assume that our parent FOR loop has already
						executed at least once. Therefore, we can
						assume that we have a previous token value
						ALREADY in the row value array and that we
						have access to a previous delimiter (in
						our delimiter array).
					--->

					<!---
						Since we are in the middle of building a
						value, we replace out double qualifiers with
						a constant. We don't care about the first
						qualifier as it can ONLY be an escaped
						qualifier (not a field qualifier).
					--->
					<cfset LOCAL.Token = LOCAL.Token.ReplaceAll(
						"\#ARGUMENTS.Qualifier#{2}",
						"{QUALIFIER}"
						) />


					<!---
						Add the token to the value we are building.
						While this is not easy to read, add it
						directly to the results array as this will
						allow us to forget about it later. Be sure
						to add the PREVIOUS delimiter since it is
						actually an embedded delimiter character
						(part of the whole field value).
					--->
					<cfset LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = (
						LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] &
						LOCAL.Delimiters[ LOCAL.TokenIndex - 1 ] &
						LOCAL.Token
						) />


					<!---
						Now that we have removed the possibly
						escaped qualifiers, let's check to see if
						this field is ending a multi-token
						qualified value (its last character is a
						field qualifier).
					--->
					<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>

						<!---
							Wooohoo! We have reached the end of a
							qualified value. We can complete this
							value and move onto the next field.
							Remove the trailing quote.

							Remember, we have already added to token
							to the results array so we must now
							manipulate the results array directly.
							Any changes made to LOCAL.Token at this
							point will not affect the results.
						--->
						<cfset LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ].ReplaceFirst( ".{1}$", "" ) />

						<!---
							Set the flag to indicate that we are no
							longer building a field value across
							tokens.
						--->
						<cfset LOCAL.IsInValue = false />

					</cfif>


				<cfelse>


					<!---
						We are NOT in the middle of building a field
						value which means that we have to be careful
						of a few special token cases:

						1. The field is qualified on both ends.
						2. The field is qualified on the start end.
					--->

					<!---
						Check to see if the beginning of the field
						is qualified. If that is the case then either
						this field is starting a multi-token value OR
						this field has a completely qualified value.
					--->
					<cfif (Left( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>


						<!---
							Delete the first character of the token.
							This is the field qualifier and we do
							NOT want to include it in the final value.
						--->
						<cfset LOCAL.Token = LOCAL.Token.ReplaceFirst(
							"^.{1}",
							""
							) />

						<!---
							Remove all double qualifiers so that we
							can test to see if the field has a
							closing qualifier.
						--->
						<cfset LOCAL.Token = LOCAL.Token.ReplaceAll(
							"\#ARGUMENTS.Qualifier#{2}",
							"{QUALIFIER}"
							) />

						<!---
							Check to see if this field is a
							self-closer. If the first character is a
							qualifier (already established) and the
							last character is also a qualifier (what
							we are about to test for), then this
							token is a fully qualified value.
						--->
						<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>

							<!---
								This token is fully qualified.
								Remove the end field qualifier and
								append it to the row data.
							--->
							<cfset ArrayAppend(
								LOCAL.Rows[ LOCAL.RowIndex ],
								LOCAL.Token.ReplaceFirst(
									".{1}$",
									""
									)
								) />

						<cfelse>

							<!---
								This token is not fully qualified
								(but the first character was a
								qualifier). We are buildling a value
								up across differen tokens. Set the
								flag for building the value.
							--->
							<cfset LOCAL.IsInValue = true />

							<!--- Add this token to the row. --->
							<cfset ArrayAppend(
								LOCAL.Rows[ LOCAL.RowIndex ],
								LOCAL.Token
								) />

						</cfif>


					<cfelse>


						<!---
							We are not dealing with a qualified
							field (even though we are using field
							qualifiers). Just add this token value
							as the next value in the row.
						--->
						<cfset ArrayAppend(
							LOCAL.Rows[ LOCAL.RowIndex ],
							LOCAL.Token
							) />


					</cfif>


				</cfif>


				<!---
					As a sort of catch-all, let's remove that
					{QUALIFIER} constant that we may have thrown
					into a field value. Do NOT use the FieldIndex
					value as this might be a corrupt value at
					this point in the token iteration.
				--->
				<cfset LOCAL.Rows[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] ) ] = Replace(
					LOCAL.Rows[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] ) ],
					"{QUALIFIER}",
					ARGUMENTS.Qualifier,
					"ALL"
					) />


			<cfelse>


				<!---
					Since we don't have a qualifier, just use the
					current raw token as the actual value. We are
					NOT going to have to worry about building values
					across tokens.
				--->
				<cfset ArrayAppend(
					LOCAL.Rows[ LOCAL.RowIndex ],
					LOCAL.Token
					) />


			</cfif>



			<!---
				Check to see if we have a next delimiter and if we
				do, is it going to start a new row? Be cautious that
				we are NOT in the middle of building a value. If we
				are building a value then the line delimiter is an
				embedded value and should not percipitate a new row.
			--->
			<cfif (
				(NOT LOCAL.IsInValue) AND
				(LOCAL.TokenIndex LT ArrayLen( LOCAL.Tokens )) AND
				(LOCAL.Delimiters[ LOCAL.TokenIndex ] EQ LOCAL.LineDelimiter)
				)>

				<!---
					The next token is indicating that we are about
					start a new row. Add a new array to the parent
					and increment the row counter.
				--->
				<cfset ArrayAppend(
					LOCAL.Rows,
					ArrayNew( 1 )
					) />

				<!--- Increment row index to point to next row. --->
				<cfset LOCAL.RowIndex = (LOCAL.RowIndex + 1) />

			</cfif>

		</cfloop>


		<!---
			ASSERT: At this point, we have parsed the CSV into an
			array of arrays (LOCAL.Rows). Now, we can take that
			array of arrays and convert it into a query.
		--->


		<!---
			To create a query that fits this array of arrays, we
			need to figure out the max length for each row as
			well as the number of records.

			The number of records is easy - it's the length of the
			array. The max field count per row is not that easy. We
			will have to iterate over each row to find the max.

			However, this works to our advantage as we can use that
			array iteration as an opportunity to build up a single
			array of empty string that we will use to pre-populate
			the query.
		--->

		<!--- Set the initial max field count. --->
		<cfset LOCAL.MaxFieldCount = 0 />

		<!---
			Set up the array of empty values. As we iterate over
			the rows, we are going to add an empty value to this
			for each record (not field) that we find.
		--->
		<cfset LOCAL.EmptyArray = ArrayNew( 1 ) />


		<!--- Loop over the records array. --->
		<cfloop
			index="LOCAL.RowIndex"
			from="1"
			to="#ArrayLen( LOCAL.Rows )#"
			step="1">

			<!--- Get the max rows encountered so far. --->
			<cfset LOCAL.MaxFieldCount = Max(
				LOCAL.MaxFieldCount,
				ArrayLen(
					LOCAL.Rows[ LOCAL.RowIndex ]
					)
				) />

			<!--- Add an empty value to the empty array. --->
			<cfset ArrayAppend(
				LOCAL.EmptyArray,
				""
				) />

		</cfloop>


		<!---
			ASSERT: At this point, LOCAL.MaxFieldCount should hold
			the number of fields in the widest row. Additionally,
			the LOCAL.EmptyArray should have the same number of
			indexes as the row array - each index containing an
			empty string.
		--->


		<!---
			Now, let's pre-populate the query with empty strings. We
			are going to create the query as all VARCHAR data
			fields, starting off with blank. Then we will override
			these values shortly.
		--->
		<cfset LOCAL.Query = QueryNew( "" ) />

		<!---
			Loop over the max number of fields and create a column
			for each records.
		--->
		<cfloop
			index="LOCAL.FieldIndex"
			from="1"
			to="#LOCAL.MaxFieldCount#"
			step="1">

			<!---
				Add a new query column. By using QueryAddColumn()
				rather than QueryAddRow() we are able to leverage
				ColdFusion's ability to add row values in bulk
				based on an array of values. Since we are going to
				pre-populate the query with empty values, we can
				just send in the EmptyArray we built previously.
			--->
			<cfset QueryAddColumn(
				LOCAL.Query,
				"COLUMN_#LOCAL.FieldIndex#",
				"CF_SQL_VARCHAR",
				LOCAL.EmptyArray
				) />

		</cfloop>


		<!---
			ASSERT: At this point, our return query LOCAL.Query
			contains enough columns and rows to handle all the
			data that we have stored in our array of arrays.
		--->


		<!---
			Loop over the array to populate the query with
			actual data. We are going to have to loop over
			each row and then each field.
		--->
		<cfloop
			index="LOCAL.RowIndex"
			from="1"
			to="#ArrayLen( LOCAL.Rows )#"
			step="1">

			<!--- Loop over the fields in this record. --->
			<cfloop
				index="LOCAL.FieldIndex"
				from="1"
				to="#ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] )#"
				step="1">

				<!---
					Update the query cell. Remember to cast string
					to make sure that the underlying Java data
					works properly.
				--->
				<cfset LOCAL.Query[ "COLUMN_#LOCAL.FieldIndex#" ][ LOCAL.RowIndex ] = JavaCast(
					"string",
					LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ]
					) />

			</cfloop>

		</cfloop>


		<!---
			Our query has been successfully populated.
			Now, return it.
		--->
		<cfreturn LOCAL.Query />

	</cffunction>


	<cfscript>
		/**
		 * Rename query columns. 
		 * Function by Julian Halliwell: https://blog.simplicityweb.co.uk/125/renaming-cfml-query-columns
		 **/
		query function queryRenameColumns( required query query, required array columnNames, required array newColumnNames ){
			// throw an error if the number of old and new names don't match
			if( arguments.columnNames.Len() != arguments.newColumnNames.Len() )
				Throw( message: "Column name mismatch", detail: "The number of column names to change doesn't match the number of new names" );
			// convert the query to JSON
			var queryJson = SerializeJSON( arguments.query );
			// get the current set of columns as an array so we can work on it
			var columns = GetMetaData( arguments.query ).Map( function( item ){
				return item.name;
			});
			// find and rename the specified columns
			var newColumns = columns.Map( function( item ){
				var foundPosition = columnNames.FindNoCase( item );
				return foundPosition? newColumnNames[ foundPosition ]: item;
			});
			// convert the original and changed column arrays to text
			var columnsJson = SerializeJSON( columns );
			var newColumnsJson = SerializeJSON( newColumns );
			// do a simple string replace (no RegExp required)
			var queryJsonColumnRenamed = queryJson.Replace( 'COLUMNS":' & columnsJson, 'COLUMNS":' & newColumnsJson );
			// convert the JSON back to a query object
			return DeserializeJSON( queryJsonColumnRenamed, false );
		}
	</cfscript>

</cfcomponent>