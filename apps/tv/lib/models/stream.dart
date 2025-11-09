class StreamInfo {
	StreamingLink? streamingLink;
	List<Server>? servers;

	StreamInfo({this.streamingLink, this.servers});

	StreamInfo.fromJson(Map<String, dynamic> json) {
		streamingLink = json['streamingLink'] != null ? new StreamingLink.fromJson(json['streamingLink']) : null;
		if (json['servers'] != null) {
			servers = <Server>[];
			json['servers'].forEach((v) { servers!.add(new Server.fromJson(v)); });
		}
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		if (this.streamingLink != null) {
      data['streamingLink'] = this.streamingLink!.toJson();
    }
		if (this.servers != null) {
      data['servers'] = this.servers!.map((v) => v.toJson()).toList();
    }
		return data;
	}
}

class StreamingLink {
	String? id;
	String? type;
	Link? link;
	List<Tracks>? tracks;
	Intro? intro;
	Intro? outro;
	String? iframe;
	String? server;

	StreamingLink({this.id, this.type, this.link, this.tracks, this.intro, this.outro, this.iframe, this.server});

	StreamingLink.fromJson(Map<String, dynamic> json) {
		id = json['id'];
		type = json['type'];
		link = json['link'] != null ? new Link.fromJson(json['link']) : null;
		if (json['tracks'] != null) {
			tracks = <Tracks>[];
			json['tracks'].forEach((v) { tracks!.add(new Tracks.fromJson(v)); });
		}
		intro = json['intro'] != null ? new Intro.fromJson(json['intro']) : null;
		outro = json['outro'] != null ? new Intro.fromJson(json['outro']) : null;
		iframe = json['iframe'];
		server = json['server'];
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		data['id'] = this.id;
		data['type'] = this.type;
		if (this.link != null) {
      data['link'] = this.link!.toJson();
    }
		if (this.tracks != null) {
      data['tracks'] = this.tracks!.map((v) => v.toJson()).toList();
    }
		if (this.intro != null) {
      data['intro'] = this.intro!.toJson();
    }
		if (this.outro != null) {
      data['outro'] = this.outro!.toJson();
    }
		data['iframe'] = this.iframe;
		data['server'] = this.server;
		return data;
	}
}

class Link {
	String? file;
	String? type;

	Link({this.file, this.type});

	Link.fromJson(Map<String, dynamic> json) {
		file = json['file'];
		type = json['type'];
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		data['file'] = this.file;
		data['type'] = this.type;
		return data;
	}
}

class Tracks {
	String? file;
	String? label;
	String? kind;
	bool? defaultId;

	Tracks({this.file, this.label, this.kind, this.defaultId});

	Tracks.fromJson(Map<String, dynamic> json) {
		file = json['file'];
		label = json['label'];
		kind = json['kind'];
		defaultId = json['default'];
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		data['file'] = this.file;
		data['label'] = this.label;
		data['kind'] = this.kind;
		data['default'] = this.defaultId;
		return data;
	}
}

class Intro {
	int? start;
	int? end;

	Intro({this.start, this.end});

	Intro.fromJson(Map<String, dynamic> json) {
		start = json['start'];
		end = json['end'];
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		data['start'] = this.start;
		data['end'] = this.end;
		return data;
	}
}

class Server {
	String? type;
	String? dataId;
	String? serverId;
	String? serverName;

	Server({this.type, this.dataId, this.serverId, this.serverName});

	Server.fromJson(Map<String, dynamic> json) {
		type = json['type'];
		dataId = json['data_id'];
		serverId = json['server_id'];
		serverName = json['serverName'];
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		data['type'] = this.type;
		data['data_id'] = this.dataId;
		data['server_id'] = this.serverId;
		data['serverName'] = this.serverName;
		return data;
	}
}

class StreamLink {
	String? id;
	String? type;
	Link? link;
	List<Tracks>? tracks;
	Intro? intro;
	Intro? outro;
	String? iframe;
	String? server;

	StreamLink({this.id, this.type, this.link, this.tracks, this.intro, this.outro, this.iframe, this.server});

	StreamLink.fromJson(Map<String, dynamic> json) {
		id = json['id'];
		type = json['type'];
		link = json['link'] != null ? new Link.fromJson(json['link']) : null;
		if (json['tracks'] != null) {
			tracks = <Tracks>[];
			json['tracks'].forEach((v) { tracks!.add(new Tracks.fromJson(v)); });
		}
		intro = json['intro'] != null ? new Intro.fromJson(json['intro']) : null;
		outro = json['outro'] != null ? new Intro.fromJson(json['outro']) : null;
		iframe = json['iframe'];
		server = json['server'];
	}

	Map<String, dynamic> toJson() {
		final Map<String, dynamic> data = new Map<String, dynamic>();
		data['id'] = this.id;
		data['type'] = this.type;
		if (this.link != null) {
      data['link'] = this.link!.toJson();
    }
		if (this.tracks != null) {
      data['tracks'] = this.tracks!.map((v) => v.toJson()).toList();
    }
		if (this.intro != null) {
      data['intro'] = this.intro!.toJson();
    }
		if (this.outro != null) {
      data['outro'] = this.outro!.toJson();
    }
		data['iframe'] = this.iframe;
		data['server'] = this.server;
		return data;
	}
}