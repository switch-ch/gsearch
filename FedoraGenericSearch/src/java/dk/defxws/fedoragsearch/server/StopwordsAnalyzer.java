package dk.defxws.fedoragsearch.server;

import java.io.IOException;
import java.io.InputStreamReader;

import org.apache.lucene.analysis.standard.StandardAnalyzer;
import org.apache.lucene.util.Version;

public class StopwordsAnalyzer extends StandardAnalyzer {
	
    public StopwordsAnalyzer() throws IOException {
    	super(Version.LUCENE_29, new InputStreamReader(StopwordsAnalyzer.class
    			.getResourceAsStream("/stopwords.txt")));
    }
}