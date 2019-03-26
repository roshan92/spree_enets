var txnRand;
var netsTxnRef;
var netsMidGlobal;
var merchantTxnRef;
var b2sTxnEndURL;
//credit
var gexp;
var gmod;
//test codes
var w;
var merchantInfo;

var gwdomain = 'https://uat2.enets.sg';
var apigwdomain = 'https://uat-api.nets.com.sg:9065/GW2/TxnReqListener';

function sendPayLoad(jSonString, hmac, apiKey) {


console.log("in sendPayLoad. gwdomain :"+gwdomain +", apigwdomain"+apigwdomain);
console.log(jSonString);


	// check if JQuery library is loaded
	if (typeof jQuery == 'undefined') {
		alert("[APPS.JS] jQuery NOT loaded ");
		var jq = document.createElement('script');
		jq.type = 'text/javascript';
		// Path to jquery.js file, eg. Google hosted version or local
		jq.src = gwdomain+'/GW2/js/jquery-3.1.1.min.js';
		document.getElementsByTagName('head')[0].appendChild(jq);

	}

	var soapiRequest = jQuery.parseJSON(jSonString);
	merchantInfo = jQuery.parseJSON(JSON.stringify(soapiRequest.msg));

	$.ajax({
		type : "POST",
		//url: "https://uat-api.nets.com.sg:9065/GW2/TxnReqListener",
		//url: apigwdomain+"/GW2/TxnReqListener",
		url: apigwdomain,
		//url : 	"http://localhost:8088/GW2/TxnReqListener",
		//url: "https://sit2.enets.sg/GW2/TxnReqListener",
		headers : {
			"KeyId" : apiKey,
			"hmac" : hmac
		},
		contentType : "application/json; charset=UTF-8",
		cache : false,
		dataType : "json",
		data : jSonString,

		success : function(data, textStatus, jqXHR) {
			var objStr = jQuery.parseJSON(JSON.stringify(data));
			var msgData = jQuery.parseJSON(JSON.stringify(objStr.msg));

			if (jQuery.isEmptyObject(msgData.merchantSvcList) || msgData.merchantSvcList.length==0 ) {
				$("#ajaxResponse").html("");
				console.log("in error condition**********");
				if (!jQuery.isEmptyObject(msgData.stageRespCode)) {
					// if merchant not sending B2SURL, send an error msg from the DIV
					if(jQuery.isEmptyObject(merchantInfo.b2sTxnEndURL)) {
						writeErrorInfo(msgData.stageRespCode, msgData.actionCode);
					}else {
						if(msgData.allDistraFlag == 'Y' || (!jQuery.isEmptyObject(msgData.hmac) && !jQuery.isEmptyObject(msgData.rawMsg)) ) {
							processErrorPage(JSON.stringify(objStr.msg),null,null,null);
						}else {
							writeErrorInfo(msgData.stageRespCode, msgData.actionCode);
						}
					}
				} else {
					// This should not be possible as it will always send stage response code
					$("#ajaxResponse").append(msgData.netsTxnMsg);
				}

			} else
//				writeErrorInfo(msgData.stageRespCode, msgData.actionCode);
				processServiceList(JSON.stringify(objStr.msg), null, null, null);
			},
		error : function(jqXHR, textStatus, errorThrown) {
		    substring = "Service Not Available";
			if(jqXHR.responseText.indexOf(substring) !== -1){
				$("#ajaxResponse").append(jqXHR.responseText);
			}
			else{
			writeErrorInfo('0010-50001', '3');
			}
		}
	});
}

function processServiceList(jSonString, selectedService, netsMid, routeTo) {

	// check if JQuery library is loaded
	if (typeof jQuery == 'undefined') {

		alert("[APPS.JS] jQuery NOT loaded ");
		var jq = document.createElement('script');
		jq.type = 'text/javascript';
		// Path to jquery.js file, eg. Google hosted version or local
		jq.src = gwdomain+'/GW2/js/jquery-3.1.1.min.js';
		document.getElementsByTagName('head')[0].appendChild(jq);

	}

	// AJAX properties for application
	var contentTypeVal = "application/json";

	var objStr = jQuery.parseJSON(jSonString);

	console.log(objStr);
	txnRand = objStr.txnRand;
	netsTxnRef = objStr.netsTxnRef;
	netsMidGlobal = netsMid;
	merchantTxnRef = objStr.merchantTxnRef;
	b2sTxnEndURL = objStr.b2sTxnEndURL;
	//creditcard
	gexp=objStr.rsaExponent;
	gmod=objStr.rsaModulus;

	console.log(gexp);
	/*
	 * alert("[APPS.JS] selectedService is: " + selectedService);
	 * alert("[APPS.JS] routeTo is: " + routeTo) alert("[APPS.JS] netsMid is: " +
	 * netsMid)
	 */

	// if undefined, it will indicate that it is an error response from FE
	/*
	 * if(typeof objStr.merchSubscribedSvcs === "undefined") {
	 * $("#ajaxResponse").append("TRANSACTION CANNOT PROCEED, PLEASE QUOTE ERROR
	 * CODE="); $("#ajaxResponse").append(objStr.netsTxnRespCode); }
	 */

	var noOfServ = objStr.merchantSvcList.length;
		console.log(" no of services "+objStr.merchantSvcList.length);
var onlyCCService = true;
//var onlyCCService = false;
var ccSNo = 0;
	// take into consideration if service list is only APS (though service list
	// is more than 1 due to subservices),
	// number of services should always be 1
	if (objStr.onlyAPSFlag == 'T') {
		noOfServ = 1;
	}
	else{

			onlyCCService = true;
				for (i = 0; i < objStr.merchantSvcList.length; i++) {
					if(objStr.merchantSvcList[i].indexOf("CC_")==-1){
						onlyCCService = false;
				}
			}
			console.log("onlyCCService : "+onlyCCService);
			console.log("objStr.currencyCode"+objStr.currencyCode);
			for (i = 0; i < objStr.merchantSvcList.length; i++) {
				if ((objStr.merchantSvcList[i].indexOf("CC_") != -1) && (objStr.merchantSvcList[i].indexOf("AMEX") == -1)) {
					// UMID will not contain multiple currency credit
					ccSNo = ccSNo + 1;
					console.log("ccSNO : "+ccSNo);
				}
				if(objStr.merchantSvcList[i].indexOf("AMEX")!=-1){
					//contains amex
					ccSNo = ccSNo + 2;
					console.log("ccSNO : "+ccSNo);
				}


			}
			if(onlyCCService){
				noOfServ = 1;
			}
	}


	if(!jQuery.isEmptyObject(objStr.walletSvcList)) {
		noOfServ = 2;
	}

	// alert("[APPS.JS] noOfServ is= " + noOfServ);

	// testing codes - to test out 1 service only
	// noOfServ = 1;
	// serviceName = 'APS_SGD_NETS2.0';
	// routeTo = 'FEH';

	// noOfServ = 1 if bypassing the OnePagePage
	// selectedsERVICE != '' if invoked from onePage and selected a service
	if (noOfServ == 1 || selectedService != null) {
	//	alert("[APPS.JS] service list is 1 or invoked via One Pager");

		var serviceName;

		// if byPass OnePager, get from merchantSvcList
		if (noOfServ == 1) {
			serviceName = objStr.merchantSvcList[0];
			routeTo = objStr.routeTo;
			//netsMid = objStr.paymtSvcInfoList[0].netsMid;
			if(onlyCCService && objStr.onlyAPSFlag != 'T'){
				serviceName = "CC_"+ccSNo;
			}
		} else { // if from OnePager
			serviceName = selectedService;
		}

		// alert("[APPS.JS] service name is: " + serviceName);

		if (serviceName == 'UPOP_SGD') {

			if (routeTo == 'FEH') {

				alert("[APPS.JS] this is UPOP");
				// making REST call now
				// create the JSON request to send 2nd request (via Consumer
				// browser) to FE
				var payRequest2 = '{"txnRand":"'
						+ objStr.txnRand
						+ '","submissionMode":"B","paymentMode":"UPOP","netsTxnRef":"'
						+ objStr.netsTxnRef + '","netsMid":"' + netsMid + '"}';

				$.ajax({
					type : "POST",
					url : gwdomain+"/GW2/processUpopFrontEnd",
					contentType : contentTypeVal,
					cache : false,
					dataType : "html",
					data : payRequest2,

					success : function(data, textStatus, jqXHR) {
						$("#ajaxResponse").html("");
						$("#ajaxResponse").append(data);
						alert("Successful");
						alert("Data to send to UPOP is: " + data);
					},
					error : function(jqXHR, textStatus, errorThrown) {
						alert("Error Encountered");
						$("#ajaxResponse").html("");
						$("#ajaxResponse").append("ERROR ENCOUNTERED");
					}
				});
			} // reserve for other routing operations (e.g. DISTRA)
		}  else if ('CC'==serviceName.slice(0, 2)) {
			// alert("This is CC");
			console.log("selected service=" + selectedService);
			if(selectedService == 'CC_MP') {
				console.log("Incoming MasterPass transaction");

				$(function() { // when DOM is ready
					// alert("DOM is ready ");
					// $("#ajaxResponse").load(
					// "https://sit2.enets.sg/GW2/credit/init"); // load the
					// sample.jsp page in the #chkcomments element

					$.post(gwdomain+"/GW2/creditFEH/redirectMasterPass", {
						txnRand : objStr.txnRand, netsMid : objStr.netsMid, routeTo:routeTo
					}, function(data, status) {
						// alert("Data: " + data + "\nStatus: " + status);
						console.log("Data received : " + status)
						console.log(data);
					//	$("#anotherSection").empty().append(data);
						$("#ajaxResponse").empty().append(data);
					});
				});

			} else {
					console.log("in credit mode");

				var paymentModeSelected = "CC";
				if(serviceName.indexOf("AMEX")!=-1){
					paymentModeSelected = "CA";
				}
				$(function() { // when DOM is ready
					// alert("DOM is ready ");
					// $("#ajaxResponse").load(
					// "https://sit2.enets.sg/GW2/credit/init"); // load the
					// sample.jsp page in the #chkcomments element

					$.post(gwdomain+"/GW2/credit/init", {
						txnRand : objStr.txnRand, paymentMode : serviceName, routeTo:routeTo
					}, function(data, status) {
						// alert("Data: " + data + "\nStatus: " + status);
						console.log("Data received : " + status)
						console.log(data);
					//	$("#anotherSection").empty().append(data);
						$("#ajaxResponse").empty().append(data);
					});
				});
			}
		} else if (serviceName == 'DD') {
			// do something here
			//222
			$(function() {
				//$.post("https://sit2.enets.sg/GW2/debit/init", {
				$.post(gwdomain+"/GW2/debit/init", {
					txnRand : objStr.txnRand, paymentMode : "DD"
				}, function(data, status) {
					// alert("Data: " + data + "\nStatus: " + status);
					console.log("Data received : " + status)
					console.log(data);
					$("#ajaxResponse").empty().append(data);
				});
			});
			//Note: The startsWith() method is not supported in IE 11 (and earlier versions).
		} else if (serviceName.indexOf('APS_SGD') == 0) {
			//	alert('this is APS_SGD');
			//		netsMid = '987669250'; // GARED for testing

			//		txnRand = objStr.txnRand;
			//		netsTxnRef = objStr.netsTxnRef;
			//		netsMidGlobal = netsMid;
			//		merchantTxnRef = objStr.merchantTxnRef;
			//		b2sTxnEndURL = objStr.b2sTxnEndURL;
			var apsRequest = '{"ss":"1","msg":{"txnRand":"' + txnRand + '","netsTxnRef":"'
					+ netsTxnRef + '","netsMid":"' + objStr.netsMid
					+ '","netsMidIndicator":"U","paymentMode":"QR"}}';

			if (routeTo == 'FEH') {
				// get the APS QR Data
				$
						.ajax({
							type : "POST",
							//url : "https://sit2.enets.sg/GW2/getApsQrData",
 							url : gwdomain+"/GW2/getApsQrData",
							contentType : contentTypeVal,
							cache : false,
							dataType : "json",
							data : apsRequest,

							success : function(data, textStatus, jqXHR) {
								var objStr = jQuery.parseJSON(JSON
										.stringify(data));
								var objMsgStr = jQuery.parseJSON(JSON.stringify(objStr.msg));

								if (jQuery.isEmptyObject(objMsgStr.qrData)) {
									$("#ajaxResponse").html("");

									if (!jQuery
											.isEmptyObject(objMsgStr.stageRespCode)) {

										//alert(objMsgStr.hmac);
										//processErrorPage(jSonString,objMsgStr.stageRespCode,objMsgStr.actionCode,objMsgStr.netsTxnMsg);

										if(!jQuery.isEmptyObject(objMsgStr.hmac) && !jQuery.isEmptyObject(objMsgStr.rawMsg) ) {
											processErrorPage(JSON.stringify(objMsgStr),null,null,null);
										} else {
											writeErrorInfo(objMsgStr.stageRespCode, objMsgStr.actionCode);
										}
									} else {
										// This should not be possible as it will always send stage response code
										$("#ajaxResponse").append(
												objMsgStr.netsTxnMsg);
									}
								} else {
									// display the APS QR Page
									$
											.ajax({
												type : "POST",
												//url : "https://sit2.enets.sg/GW2/displayQrPage/?serviceName=" + serviceName,
												url : gwdomain+"/GW2/displayQrPage/?serviceName=" + serviceName,
												contentType : contentTypeVal,
												cache : false,
												dataType : "html",
												data : objMsgStr.qrData,

												success : function(data,
														textStatus, jqXHR) {
													var agentStopIndicator = "0";
													$("#ajaxResponse")
															.html("");
													$("#ajaxResponse").append(
															data);

													var retryCount = 0;

													// do the APS Query
													// asynchronously
													var apsQuery = '{"ss":"1","msg":{"txnRand":"'
															+ txnRand
															+ '","netsTxnRef":"'
															+ netsTxnRef
															+ '","b2sTxnEndURL":"'
															+ b2sTxnEndURL
															+ '","paymentMode":"QR"}}';

													ApsQueryFnc= function() {
														$
															.ajax({
																type : "POST",
																//url : "https://sit2.enets.sg/GW2/doApsQuery",
																url : gwdomain+"/GW2/doApsQuery",
																contentType : contentTypeVal,
																cache : false,
																dataType : "html",
																data : apsQuery,

																success : function(
																		data,
																		textStatus,
																		jqXHR) {

																	retryCount = retryCount + 1;

																	//alert("retryCount=" + retryCount);
																	var apsStageRespCode = $(data).find("#apsStageRespCode").val();

																	if(apsStageRespCode=='0050-50002' || apsStageRespCode=='0050-50003' ||
																	   apsStageRespCode=='0050-50004' || apsStageRespCode=='0060-50002'	){
																		var apsActionCode = $(data).find("#apsActionCode").val();
																//		processErrorPage(JSON.stringify(objStr.msg));
																//		processErrorPage(jSonString,apsStageRespCode,apsActionCode,objMsgStr.netsTxnMsg);
																		writeErrorInfo(apsStageRespCode, apsActionCode);
																	}else {

																		if(retryCount == 1) {
																			if(apsStageRespCode=='3000-00000') {
																				ApsQueryFnc();
																			}else {
																				$(
																				"#ajaxResponse")
																				.html("");
																				$(
																				"#ajaxResponse")
																				.append(data);
																			}
																		} else if(retryCount > 1){
																			$(
																			"#ajaxResponse")
																			.html(
																					"");
																			$(
																			"#ajaxResponse")
																			.append(
																					data);
																		}
																	}

																},
																error : function(

																		jqXHR,
																		textStatus,
																		errorThrown) {

																		if(jqXHR.status == 504)
																		{
																			retryCount = retryCount + 1;

																			if(retryCount == 1) {
																				ApsQueryFnc();
																			} else if(retryCount > 1){
																					writeErrorInfo('0050-50002', '2');
																			}
																		}
																}
															});
													}
													ApsQueryFnc();
												},
												error : function(jqXHR,
														textStatus, errorThrown) {
													// This should not be possible as it will always send stage response code
													if(jqXHR.status == 404){
														writeErrorInfo('0040-50002', '1');
													} else { // if not 200 should be a set-up error
														$("#ajaxResponse").html("");
														$("#ajaxResponse")
														.append(
																"<b>INTERNAL SYSTEM ERROR ON DISPLAY OF APS QR PAGE</b>");
													}
												}

											});
								}
							},
							error : function(jqXHR, textStatus, errorThrown) {
								// This should not be possible as it will always send stage response code

								if(jqXHR.status == 404){
									writeErrorInfo('0030-50002', '1');
								} else { // if not 200 should be a set-up error
									$("#ajaxResponse").html("");
									$("#ajaxResponse")
										.append(
												"<b>INTERNAL SYSTEM ERROR ON APS QR DATA</b>");
								}

							}
						});
			}
		}

	} else {
		$
		.ajax({
			type : "POST",
			url : gwdomain+"/GW2/prepareOnePager",
			contentType : "application/json",
			cache : false,
			dataType : "html",
			data : jSonString,
			success : function(data, textStatus, jqXHR) {
				$("#ajaxResponse").html("");
				$("#ajaxResponse").append(data);
			},
			error : function(jqXHR, textStatus, errorThrown) {
				writeErrorInfo("0010-50002", "1");
		/*		$("#ajaxResponse").html("");
				$("#ajaxResponse")
					.append(
							"<b>INTERNAL SYSTEM ERROR WHEN DISPLAYING PAYMENT SELECTION</b>");*/
			}
		});
	}
}


function processErrorPage(pMsgData, pStageRespCode, pActionCode, pNetsTxnMsg){
	$.post(gwdomain+"/GW2/processErrorPage", {
		msgData : pMsgData, stageRespCode : pStageRespCode, actionCode : pActionCode, netsTxnMsg : pNetsTxnMsg, b2sTxnUrl: merchantInfo.b2sTxnEndURL
	})
	.done(function(data, status) {
		// alert("Data: " + data + "\nStatus: " + status);
		console.log("Data received : " + status);
		console.log(data);

		if(data == '') {
			$("#ajaxResponse").html("");
			$("#ajaxResponse")
				.append(
						"<b>INTERNAL SYSTEM ERROR OCCURED</b>");
		} else {
			$("#anotherSection").empty().append(data);
		}
	})
	.fail(function(xhr, status, error) {
		$("#ajaxResponse").html("");
		$("#ajaxResponse")
			.append(
					"<b>INTERNAL SYSTEM ERROR OCCURED</b>");
    });

}

function cancelTransaction() {
	// check if JQuery library is loaded
	if (typeof jQuery == 'undefined') {
		alert("[APPS.JS] jQuery NOT loaded ");
		var jq = document.createElement('script');
		jq.type = 'text/javascript';
		// Path to jquery.js file, eg. Google hosted version or local
		jq.src = gwdomain+'/GW2/js/jquery-3.1.1.min.js';
		document.getElementsByTagName('head')[0].appendChild(jq);

	}

//	netsMidGlobal = '987669250'; // GARED for testing

	var cancelRequest = '{"txnRand":"'
			+ txnRand
			+ '","merchantTxnRef":"'
			+ merchantTxnRef
			+ '","netsMid":"'
			+ netsMidGlobal
			+ '","netsTxnRef":"'
			+ netsTxnRef
			+ '","b2sTxnEndURL":"'
			+ b2sTxnEndURL
			+ '","netsMidIndicator":"U","paymentMode":"APS","submissionMode":"B"}';

	// call to the main generic controller to get the Txn Res containing the
	// service list
	$.ajax({
		type : "POST",
		url : gwdomain+"/GW2/cancelEnetsTxn",
		contentType : "application/json",
		cache : false,
		dataType : "html",
		data : cancelRequest,
		success : function(data, textStatus, jqXHR) {
			$("#ajaxResponse").html("");
			$("#ajaxResponse").append(data);
		},
		error : function(jqXHR, textStatus, errorThrown) {
			$("#ajaxResponse").append("<b>[ERROR] INTERNAL SYSTEM ERROR</b>");
		}
	});

}

function writeErrorInfo(stageResponseCode, actionCode){

	$("#ajaxResponse").html("");
	$("#ajaxResponse").append("<b>Please quote ERROR CODE=" + stageResponseCode + " and ACTION CODE="
								+ actionCode + " with the below merchant information:</b><br>");

	$("#ajaxResponse").append("<b>Merchant ID=" + merchantInfo.netsMid + "</b><br>");
	$("#ajaxResponse").append("<b>Transaction Date Time =" + merchantInfo.merchantTxnDtm + "</b><br>");
	$("#ajaxResponse").append("<b>Merchant Reference=" + merchantInfo.merchantTxnRef + "</b>");


}
