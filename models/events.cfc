/**
 * Name: DPD Tracking Event Manager
 * Author: Gary Stanton (@SimianE)
 * Description: Handles the use of DPD UK 'tracking event' EDI files stored on the DPD SFTP server. 
 * You will need to contact DPD to have them set up access for your account.
 * A private RSA2048 keyfile must be used in order to connect to the DPD server, and you will need to provide the public sftpKeyfile to DPD.
 * Files stored on the server are intended to be downloaded, processed and then deleted.
 */
component singleton accessors="true" {

	property name="sftpServer"      type="string" default="sftp.dpdgroup.co.uk";
	property name="sftpUsername"    type="string";
	property name="sftpKeyfile"     type="string";
	property name="filePath" 		type="string" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#../store/";
	property name="connectionName"  type="string" default="DPDConnection_#CreateUUID()#";
	property name="connectionOpen"  type="boolean" default="false";


	/**
	 * Constructor
	 * 
	 * @sftpServer 		The location of the DPD SFTP server. Defaults to sftp.dpdgroup.co.uk
	 * @sftpUsername    Your SFTP sftpUsername, provided by DPD UK
	 * @sftpKeyfile     The location of your private key file used for authentication. Should be a .ppk file hosted on the server.
	 * @filePath    	The filesystem location to use when processing files. Defaults to /store.
	 */
	public events function init(
			string sftpServer
		,   required string sftpUsername
		,   required string sftpKeyfile
		,   string filePath
	){  
		if (structKeyExists(Arguments, 'sftpServer')) {
			setSftpServer(Arguments.sftpServer);
		}

		setSftpUsername(Arguments.sftpUsername);

		// Check sftpKeyfile exists
		if (!fileExists(Arguments.sftpKeyfile)) {
			throw('Keyfile does not exist on the server at: #Arguments.sftpKeyFile#');
		}
		else {
			setSftpKeyfile(Arguments.sftpKeyfile);
		}

		// Create file store
		if (!directoryExists(getFilePath())) {
			DirectoryCreate(getFilePath());
		}

		return this;
	}


	private function openConnection() {
		// Open FTP connection
		cfftp(
				action = "open"
			,   connection = getConnectionName()
			,   username = getSftpUsername()
			,   server = getSftpServer()
			,   key = getsftpKeyFile()
			,   secure = true
			,   stoponerror = true
		);

		setConnectionOpen(cfftp.succeeded);

		return cfftp;
	}


	private function closeConnection() {
		cfftp(
			action = "close"
		,   connection = getConnectionName()
		,   stoponerror = true
		);

		setConnectionOpen(cfftp.succeeded);

		return cfftp;
	}


	private function getFileListCommand() {
		cfftp(
			action = "listdir"
		,   connection = getConnectionName()
		,   directory="OUT"
		,   name = "Local.DPDFiles"
		,   stoponerror = true
		);

		// Sort files
		Local.DPDFiles = queryExecute("
			SELECT * FROM Local.DPDFiles
			ORDER BY LastModified ASC
		", {} , {dbtype="query"});

		return Local.DPDFiles;
	}


	private function retrieveFileCommand(
			required string fileName
		,	boolean removeFromServer = false
	) {

		cfftp(
			action = "getFile"
		,   connection = getConnectionName()
		,   remoteFile = 'OUT/' & Arguments.fileName
		,	localFile = getFilePath() & Arguments.fileName
		,   stoponerror = true
		,	failIfExists = false
		);

		if (Arguments.removeFromServer) {
			deleteFileCommand(Arguments.fileName);
		}

		return cfftp;
	}


	private function deleteFileCommand(
			required string fileName
	) {
		cfftp(
			action = "remove"
		,   connection = getConnectionName()
		,   item = 'OUT/' & Arguments.fileName
		,   stoponerror = true
		);

		return cfftp;
	}

	/**
	 * Returns a query object of files on the SFTP server
	 */
	public function getFileList() {
		openConnection();
		Local.fileList = getFileListCommand();
		closeConnection();

		return Local.fileList;
	}


	/**
	 * Delete a file from the FTP server
	 */
	public function deleteFile(
		required string FileName
	) {
		openConnection();
		Local.result = deleteFileCommand(Arguments.FileName);
		closeConnection();

		return Local.result;
	}



	/**
	 * Filter a file list query object by name and/or date
	 *
	 * @fileNames 			Optionally provide a specific filename or list of filenames
	 * @dateRange			Optionally provide a comma separated (inclusive) date range (yyyy-mm-dd,yyyy-mm-dd) to filter files. Where a single date is passed, all files from that date will be included.
	 *
	 * @return     			Query object containing tracking event data
	 */
	public function filterFileList(
			query fileList
		,	string fileNames
		,	string dateRange
		,	numeric maxFiles = 0
	) {
		
		var fileList = StructKeyExists(Arguments, 'fileList') ? Arguments.fileList : getFileList();

		// If we're looking at a local file list, we'll have 'dateLastModified' instead of 'lastModified'
		Local.modifiedColumnName = StructKeyExists(fileList, 'dateLastModified') ? 'dateLastModified' : 'lastModified';

		// Filter query
		Local.SQL = "
			SELECT * 
			FROM fileList
			WHERE 1 = 1
		";

		Local.Params = {};

		if (structKeyExists(Arguments, 'fileNames')) {
			Local.SQL &= "
				AND 	name IN (:filenames)
			";

			Local.Params.filenames = {value = Arguments.fileNames, list = true};
		}

		if (structKeyExists(Arguments, 'dateRange')) {
			Local.SQL &= "
				AND 	#Local.modifiedColumnName# >= :DateFrom
			";

			Local.Params.DateFrom = {value = DateFormat(ListFirst(Arguments.dateRange), 'yyyy-mm-dd')};
		}

		if (structKeyExists(Arguments, 'dateRange') && listLen(Arguments.DateRange) == 2) {
			Local.SQL &= "
				AND 	#Local.modifiedColumnName# < :DateTo
			";

			Local.Params.DateTo = {value = DateAdd('d', 1, DateFormat(ListLast(Arguments.dateRange), 'yyyy-mm-dd'))};
		}

		Local.fileList = queryExecute(Local.SQL, Local.params , {dbtype="query", maxrows=Arguments.MaxFiles > 0 ? Arguments.MaxFiles : 9999999});

		return Local.fileList;
	}



	/**
	 * Retrieve files from the DPD UK SFTP server and return a query object containing their data
	 *
	 * @fileNames 			Optionally provide a specific filename or list of filenames to process
	 * @dateRange			Optionally provide a comma separated (inclusive) date range (yyyy-mm-dd,yyyy-mm-dd) to filter files to process. Where a single date is passed, all files from that date will be included.
	 * @removeFromServer  	When true, processed files are removed from the remote server
	 *
	 * @return     			Query object containing tracking event data
	 */
	public function processRemoteFiles(
			string fileNames
		,	string dateRange
		,	boolean removeFromServer = false
		,	numeric maxFiles = 0
	) {

		openConnection();

		Local.fileList = filterFileList(
			fileList 			= getFileListCommand()
		,	ArgumentCollection 	= Arguments
		);		

		// Array to store local filenames
		Local.localFiles = [];

		// Loop through the files and process
		for (Local.thisFile in Local.fileList) {
			Local.retrieveFile = retrieveFileCommand(Local.thisFile.name, Arguments.removeFromServer);

			if (Local.retrieveFile.succeeded) {
				Local.localFiles.append(Local.thisFile.name);
			}
		}

		closeConnection();

		// Process local files
		if (Local.localFiles.len()) {
			Local.queryObject = processLocalFiles(arrayToList(Local.LocalFiles))

			return Local.queryObject;
		}
		else {
			return 'No matching files found.';
		}
	}


	public function processLocalFiles(
			string fileNames
		,	string dateRange
		,	numeric maxFiles = 0
	) {
		// Get file query object
		Local.fileList = filterFileList(
			fileList 			= directoryList(getFilePath(), false, 'query')
		,	ArgumentCollection 	= Arguments
		);

		Local.colList = 'Parcel_Number,Log_Type,Event_Date,Event_Time,Event_Location,Event_Description,Consignment_Number,Consignment_Line,Account_Number,Senders_Ref,Checklist_Question_Code,Checklist_Question_Description,Checklist_Response';
		Local.queryObject = queryNew(Local.colList);
		Local.queryObject.addColumn('Filename');

		Local.conversion = new conversion();

		for (Local.thisFile in Local.fileList) {
			Local.data = Local.conversion.CSVToQuery(fileRead(getFilePath() & Local.thisFile.name));
			Local.data = Local.conversion.queryRenameColumns(Local.data, ListToArray(Local.data.columnList), ListToArray(Local.colList)); // Rename columns, as the CSVToQuery function returns numbered columns

			for (Local.thisRow in Local.data) {
				// DPD files end with the number of rows, and a blank line. If there's nothing in the log type column, we're at the end of the file.
				if (isNumeric(Local.thisRow.Log_Type)) {
					Local.queryObject.addRow(Local.thisRow);
					Local.queryObject.fileName[Local.queryObject.RecordCount] = Local.thisFile.name;
				}
			}
		}

		return Local.queryObject;
	}
}