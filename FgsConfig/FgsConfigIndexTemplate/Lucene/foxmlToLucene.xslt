<?xml version="1.0" encoding="UTF-8"?> 
<!-- $Id: demoFoxmlToLucene.xslt 5734 2006-11-28 11:20:15Z gertsp $ -->
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"   
    	xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
    		exclude-result-prefixes="exts"
		xmlns:str="http://exslt.org/strings"
		xmlns:zs="http://www.loc.gov/zing/srw/"
		xmlns:foxml="info:fedora/fedora-system:def/foxml#"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
		xmlns:uvalibdesc="http://dl.lib.virginia.edu/bin/dtd/descmeta/descmeta.dtd"
		xmlns:uvalibadmin="http://dl.lib.virginia.edu/bin/admin/admin.dtd/">
	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
	<!-- 
	<xsl:include href="uvalibdescToLucene.xslt"/>
	 -->
		
	<xsl:param name="REPOSITORYNAME" select="'reposName'"/>
	<xsl:param name="REPOSBASEURL" select="'http://localhost:8080/fedora'"/>
	<xsl:param name="FEDORASOAP" select="'http://localhost:8080/fedora/services'"/>
	<xsl:param name="FEDORAUSER" select="'fedoraUser'"/>
	<xsl:param name="FEDORAPASS" select="'fedoraPass'"/>
	<xsl:param name="TRUSTSTOREPATH" select="'trustStorePath'"/>
	<xsl:param name="TRUSTSTOREPASS" select="'trustStorePass'"/>
<!--
	 This xslt stylesheet generates the IndexDocument consisting of IndexFields
     from a FOXML record. The IndexFields are:
       - from the root element = PID
       - from foxml:property   = type, state, contentModel, ...
       - from oai_dc:dc        = title, creator, ...
     The IndexDocument element gets a PID attribute, which is mandatory,
     while the PID IndexField is optional.
     Options for tailoring:
       - IndexField types, see Lucene javadoc for Field.Store, Field.Index, Field.TermVector
       - IndexField boosts, see Lucene documentation for explanation
       - IndexDocument boosts, see Lucene documentation for explanation
       - generation of IndexFields from other XML metadata streams than DC
         - e.g. as for uvalibdesc included above and called below, the XML is inline
         - for not inline XML, the datastream may be fetched with the document() function,
           see the example below (however, none of the demo objects can test this)
       - generation of IndexFields from other datastream types than XML
         - from datastream by ID, text fetched, if mimetype can be handled
         - from datastream by sequence of mimetypes, 
           text fetched from the first mimetype that can be handled,
           default sequence given in properties.
-->

	<xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>
	<xsl:variable name="docBoost" select="1.4*2.5"/> <!-- or any other calculation, default boost is 1.0 -->
	
	<xsl:template match="/">
		<IndexDocument> 
		    <!-- The PID attribute is mandatory for indexing to work -->
			<xsl:attribute name="PID">
				<xsl:value-of select="$PID"/>
			</xsl:attribute>
			<xsl:attribute name="boost">
				<xsl:value-of select="$docBoost"/>
			</xsl:attribute>
		<!-- The following allows only active FedoraObjects to be indexed. -->
		<xsl:if test="foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state' and @VALUE='Active']">
			<xsl:if test="not(foxml:digitalObject/foxml:datastream[@ID='METHODMAP'] or foxml:digitalObject/foxml:datastream[@ID='DS-COMPOSITE-MODEL'])">
				<xsl:if test="starts-with($PID,'')">
					<xsl:apply-templates mode="activeFedoraObject"/>
				</xsl:if>
			</xsl:if>
		</xsl:if>
		</IndexDocument>
	</xsl:template>

	<xsl:template match="/foxml:digitalObject" mode="activeFedoraObject">
		    <!-- The PID index field lets you search on the PID value -->
			<IndexField IFname="PID" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
				<xsl:value-of select="$PID"/>
			</IndexField>
			<IndexField IFname="REPOSITORYNAME" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
				<xsl:value-of select="$REPOSITORYNAME"/>
			</IndexField>
			<IndexField IFname="REPOSBASEURL" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
				<xsl:value-of select="str:replace($FEDORASOAP,'/services','')"/>
			</IndexField>
			<xsl:for-each select="foxml:objectProperties/foxml:property">
				<IndexField index="UN_TOKENIZED" store="YES" termVector="NO">
					<xsl:attribute name="IFname"> 
						<xsl:value-of select="concat('fgs.', substring-after(@NAME,'#'))"/>
					</xsl:attribute>
					<xsl:value-of select="@VALUE"/>
				</IndexField>
			</xsl:for-each>
			<xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/*">
				<IndexField index="TOKENIZED" store="YES" termVector="YES">
					<xsl:attribute name="IFname">
						<xsl:value-of select="concat('dc.', substring-after(name(),':'))"/>
					</xsl:attribute>
					<xsl:value-of select="text()"/>
				</IndexField>
			</xsl:for-each>
			
			<!-- uvalibdesc is an example of inline metadata XML, used in demo:10 and demo:11.
			     IndexFields are generated by the template in the included file. -->
			<!-- 
			<xsl:call-template name="uvalibdesc"/>
			 -->

			<!-- a managed datastream is fetched, if its mimetype 
			     can be handled, the text becomes the value of the field. -->
			<xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M' or @CONTROL_GROUP='E']">
				<IndexField index="TOKENIZED" store="YES" termVector="NO">
					<xsl:attribute name="IFname">
						<xsl:value-of select="concat('dsm.', @ID)"/>
					</xsl:attribute>
					<xsl:value-of select="exts:getDatastreamText($PID, $REPOSITORYNAME, @ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
				</IndexField>
			</xsl:for-each>

			<!-- a dissemination identified in bDefPid, methodName, parameters, asOfDateTime is fetched,  
			     if its mimetype can be handled, the text becomes the value of the IndexField. 
			     parameters format is 'name=value name2=value2'-->
			     
			<!-- uncomment it, if you wish, it takes time, even if the foxml has no disseminators.
			<IndexField IFname="fgs.Diss.text" index="TOKENIZED" store="YES" termVector="NO"
						bDefPid="demo:19" methodName="getPDF" parameters="" asOfDateTime="" >
			</IndexField>
			-->

			<!-- for not inline XML, the datastream may be fetched with the document() function,
                 none of the demo objects can test this,
                 however, it has been tested with a managed xml called RIGHTS2 added to demo:10 with fedora-admin -->
			     
			<!-- uncomment it, if you wish, it takes time, even if the foxml has no RIGHTS2 datastream.
			<xsl:call-template name="example-of-xml-not-inline"/>
			-->

			<!-- This is an example of calling an extension function, see Apache Xalan, may be used for filters.
			<IndexField IFname="fgs.DS" index="TOKENIZED" store="YES" termVector="NO">
				<xsl:value-of select="exts:someMethod($PID)"/>
			</IndexField>
			-->
			
	</xsl:template>
	

	<xsl:template name="example-of-xml-not-inline">
			<IndexField IFname="uva.access" index="TOKENIZED" store="YES" termVector="NO">
				<xsl:value-of select="document(concat('https://localhost:8943/fedora/get/', $PID, '/RIGHTS2'))/uvalibadmin:admin/uvalibadmin:adminrights/uvalibadmin:policy/uvalibadmin:access"/>
			</IndexField>
	</xsl:template>
	
</xsl:stylesheet>	
