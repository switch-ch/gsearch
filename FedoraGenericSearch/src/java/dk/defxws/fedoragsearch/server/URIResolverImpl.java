/*
 * <p><b>License and Copyright: </b>The contents of this file is subject to the
 * same open source license as the Fedora Repository System at www.fedora-commons.org
 * Copyright &copy; 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 by The Technical University of Denmark.
 * All rights reserved.</p>
 */
package dk.defxws.fedoragsearch.server;

import java.net.MalformedURLException;
import java.net.URL;

import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.URIResolver;
import javax.xml.transform.stream.StreamSource;

import org.apache.commons.httpclient.UsernamePasswordCredentials;
import org.apache.log4j.Logger;

import org.fcrepo.common.http.WebClient;

/**
 * custom URIResolver for ssl access to fedora repository
 * 
 * @author  gsp@dtv.dk
 * @version 
 */
public class URIResolverImpl implements URIResolver {
	
	private Config config;
    
    private final Logger logger = Logger.getLogger(URIResolverImpl.class);
    
    public void setConfig(Config config) {
		this.config = config;
    }

	public Source resolve(String href, String base) throws TransformerException {
		Source source = null;
		URL url;
		try {
			url = new URL(href);
		} catch (MalformedURLException e) {
			// the XSLT processor should try to resolve the URI itself, 
			// here it may be a location path, which it can resolve
	        if (logger.isDebugEnabled())
	            logger.debug("resolve back to XSLT processor MalformedURLException href="+href+" base="+base+" exception="+e);
			return null;
		}
		String reposName = config.getRepositoryNameFromUrl(url);
		if (reposName == null || reposName.length() == 0) {
			// here other resolve mechanism may be coded, or
			// the XSLT processor should try to resolve the URI itself,
			// e.g. it can resolve the file protocol
	        if (logger.isDebugEnabled())
	            logger.debug("resolve back to XSLT processor no reposName href="+href+" base="+base+" url="+url.toString());
			return null;
		}
        if (logger.isDebugEnabled())
            logger.debug("resolve get from repository href="+href+" base="+base+" url="+url.toString()+" reposName="+reposName);
		System.setProperty("javax.net.ssl.trustStore", config.getTrustStorePath(reposName));
		System.setProperty("javax.net.ssl.trustStorePassword", config.getTrustStorePass(reposName));
		WebClient client = new WebClient();
		try {
	        if (logger.isDebugEnabled())
	            logger.debug("resolve get from reposName="+reposName+" source=\n"+client.getResponseAsString(href, false, new UsernamePasswordCredentials(config.getFedoraUser(reposName), config.getFedoraPass(reposName))));
			source = new StreamSource(client.get(href, false, config.getFedoraUser(reposName), config.getFedoraPass(reposName)));
		} catch (Exception e) {
			throw new TransformerException("resolve get from reposName="+reposName+" href="+href+" base="+base+" exception=\n", e);
		}
		return source;
	}

}
