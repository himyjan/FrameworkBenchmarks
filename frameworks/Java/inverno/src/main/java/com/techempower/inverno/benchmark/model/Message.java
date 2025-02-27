package com.techempower.inverno.benchmark.model;

import com.dslplatform.json.CompiledJson;

@CompiledJson
public final class Message {

	private final String message;
	
	public Message(String message) {
		this.message = message;
	}

	public String getMessage() {
		return this.message;
	}
}