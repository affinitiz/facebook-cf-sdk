﻿/**
  * Copyright 2010 Affinitiz
  * Author: Benoit Hediard (hediard@affinitiz.com)
  *
  * Licensed under the Apache License, Version 2.0 (the "License"); you may
  * not use this file except in compliance with the License. You may obtain
  * a copy of the License at
  * 
  *  http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
  * License for the specific language governing permissions and limitations
  * under the License.
  *
  * @displayname Facebook Rest API
  * @hint A client wrapper to call the old Facebook Rest API
  * 
  */
component accessors="true" {
	
	/*
	 * @description Facebook Rest API constructor
	 * @hint Requires an application or user accessToken
	 */
	public FacebookRestAPI function init(String accessToken = "") {
		variables.ACCESS_TOKEN = arguments.accessToken;
		return this;
	}
	
	public Any function call(required String method, String returnFormat = "json") {
		var httpService = new Http(url="https://api.facebook.com/method/#arguments.method#");
		var name = "";
		httpService.addParam(type="url", name="access_token", value="#variables.ACCESS_TOKEN#");
		for (name in arguments) {
			if (name != "method") {
				httpService.addParam(type="url", name="#name#", value="#arguments[name]#");
			}
		}
		httpService.addParam(type="url", name="format", value="#returnformat#");
		return makeRequest(httpService);
	}
	
	/*
	 * @description Execute multiple FQL Query.
	 * @hint Return an array of query results.
	 */
	public Struct function executeMultipleQuery(required Array queries, String returnFormat = "json") {
		var queryResults = structNew();
		var result = call(method="fql.multiquery", queries=serializeJSON(arguments.queries), returnFormat=arguments.returnFormat);
		if (isArray(result)) {
			for (var i=1; i <= arrayLen(result); i++) {
				queryResults[result[i].name] = result[i].fql_result_set;
			}
		}
		return queryResults;
	}
	
	/*
	 * @description Execute a FQL Query.
	 * @hint 
	 */
	public Array function executeQuery(required String query, String returnFormat = "json") {
		var queryResult = arrayNew(1);
		var result = call(method="fql.query", query=arguments.query, returnFormat=arguments.returnFormat);
		if (isArray(result)) {
			queryResult = result;
		}
		return queryResult;
	}
	
	public String function publishAlbum(required String profileId, required String name, required String description) {
		var result = structNew();
		var httpService = new Http(url="https://api.facebook.com/method/photos.createAlbum");
		httpService.addParam(type="url", name="access_token", value="#variables.ACCESS_TOKEN#");
		httpService.addParam(type="url", name="name", value="#arguments.name#");
		httpService.addParam(type="url", name="description", value="#arguments.description#");
		httpService.addParam(type="url", name="uid", value="#arguments.profileId#");
		httpService.addParam(type="url", name="format", value="json");
		result = makeRequest(httpService);
		return result['aid'];
	}
	
	public String function publishPhoto(required String profileId, required String albumId, required String sourcePath, String message = "") {
		var result = structNew();
		var httpService = new Http(url="https://api.facebook.com/method/photos.upload", method="POST");
		httpService.addParam(type="url", name="access_token", value="#variables.ACCESS_TOKEN#");
		httpService.addParam(type="url", name="aid", value="#arguments.albumId#");
		httpService.addParam(type="url", name="uid", value="#arguments.profileId#");
		httpService.addParam(type="file", name="data", file="#arguments.sourcePath#");
		httpService.addParam(type="url", name="format", value="json");
		if (trim(arguments.message) != "") httpService.addParam(type="formField", name="message", value="#arguments.message#");
		result = makeRequest(httpService);
		return result['pid'];
	}
	
	// PRIVATE
	
	private Any function makeRequest(required Http httpService) {
		var response = arguments.httpService.send().getPrefix();
		var result = structNew();
		if (isJSON(response.fileContent)) {
			result = deserializeJSON(response.fileContent);
			if (isStruct(result) && structKeyExists(result, "error_code")) {
				throw(message="#result.error_msg#", type="Facebook API error #result.error_code#");
			}
		} else {
			result = response;
			if (response.statusCode != "200 OK") {
				throw(message="#response.statusCode#", type="Facebook HTTP");
			}
		}
		return result;
	}

}