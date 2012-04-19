<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" exclude-result-prefixes="exts" 
                xmlns:audit="info:fedora/fedora-system:def/audit#" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl" 
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                xmlns:dtu_meta="http://www.dtu.dk/dtu_meta/" 
                xmlns:foxml="info:fedora/fedora-system:def/foxml#" 
                xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" 
                xmlns:dc="http://purl.org/dc/elements/1.1/" 
                xmlns:meta="http://www.dtu.dk/dtu_meta/meta/" 
                xmlns:dcterms="http://purl.org/dc/terms/" 
                xmlns:oai="http://www.openarchives.org/OAI/2.0/" 
                xmlns:chor_dc="http://purl.org/switch/chor/" 
                xmlns:chor_dcterms="http://purl.org/switch/chor/terms/" 
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
                xmlns:rel="info:fedora/fedora-system:def/relations-external#" 
                xmlns:fedora-model="info:fedora/fedora-system:def/model#">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:param name="REPOSITORYNAME" select="'FgsRepos'"/>
  <xsl:param name="REPOSBASEURL" select="'http://localhost:8080/fedora'"/>
  <xsl:param name="FEDORASOAP" select="'http://localhost:8080/fedora/services'"/>
  <xsl:param name="FEDORAUSER" select="'fedoraAdmin'"/>
  <xsl:param name="FEDORAPASS" select="'fedoraAdmin'"/>
  <xsl:param name="TRUSTSTOREPATH" select="'trustStorePath'"/>
  <xsl:param name="TRUSTSTOREPASS" select="'trustStorePass'"/>
  <xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>

  <xsl:template match="/">
    <IndexDocument boost="1.0">
      <xsl:attribute name="PID">
        <xsl:value-of select="$PID"/>
      </xsl:attribute>
      <!--The PID attribute is mandatory for indexing to work-->
      <!--The following allows only active FedoraObjects to be indexed.-->
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
    <!--The PID index field lets you search on the PID value-->
    <IndexField IFname="PID" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
      <xsl:value-of select="$PID"/>
    </IndexField>
    <IndexField IFname="REPOSITORYNAME" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
      <xsl:value-of select="$REPOSITORYNAME"/>
    </IndexField>
    <IndexField IFname="REPOSBASEURL" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
      <xsl:value-of select="substring($FEDORASOAP, 1, string-length($FEDORASOAP)-9)"/>
    </IndexField>
    <IndexField IFname="TITLE_UNTOK" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
      <xsl:value-of select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/dc:title"/>
    </IndexField>
    <IndexField IFname="AUTHOR_UNTOK" index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0">
      <xsl:value-of select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/dc:creator"/>
    </IndexField>

    <!--indexing foxml property fields-->
    <xsl:for-each select="foxml:objectProperties/foxml:property">
      <IndexField index="UN_TOKENIZED" store="YES" termVector="NO">
        <xsl:attribute name="IFname">
          <xsl:value-of select="concat('fgs.', substring-after(@NAME,'#'))"/>
        </xsl:attribute>
        <xsl:value-of select="@VALUE"/>
      </IndexField>
    </xsl:for-each>


    <xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/chor_dc:dc/*">
      <IndexField index="TOKENIZED" store="YES" termVector="YES">
        <xsl:attribute name="IFname">
          <xsl:value-of select="concat(substring-before(name(),':'), '.', substring-after(name(),':'))"/>
          <!--  <xsl:value-of select="concat('dc.', substring-after(name(),':'))"/>-->
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </IndexField>
    </xsl:for-each>

    <!--Author: ChR - Date: 2008-08-11
        This gets the discipline as defined by us from dcterms:subject
    -->
    <xsl:if test="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/chor_dc:dc/dcterms:subject[@xsi:type='chor_dcterms:discipline']">
      <IndexField IFname="chor_dcterms.discipline" index="UN_TOKENIZED" store="YES" termVector="YES">
        <xsl:value-of select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/chor_dc:dc/dcterms:subject/text()"/>
      </IndexField>
    </xsl:if>

    <!--Author: ChR - Date: 2009-08-26
        This gets the attribute from the "creator" element of CHOR_DC. Has to be tokenized in order to be sortable
    -->
    <IndexField IFname="chor_dcterms.creatorSorted" index="UN_TOKENIZED" store="YES" termVector="YES">
      <xsl:value-of select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/chor_dc:dc/dcterms:creator/text()"/>
    </IndexField>

    <!--Author: ChR - Date: 2008-07-31
        This gets the attribute from the "accessRights" and "rights" element of CHOR_DC
    -->
    <IndexField IFname="chor_dcterms.accessRightsAttribute" index="TOKENIZED" store="YES" termVector="YES">
      <xsl:value-of select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/chor_dc:dc/dcterms:accessRights/@chor_dcterms:access"/>
    </IndexField>
    <IndexField IFname="chor_dcterms.rightsAttribute" index="TOKENIZED" store="YES" termVector="YES">
      <xsl:value-of select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/chor_dc:dc/dcterms:rights/@chor_dcterms:access"/>
    </IndexField>

    <!-- Author: ChR Date: 2008-07-24 
         This will index the fields MIMETYPE, FORMAT_URI and LABEL of each datastream. This is needed for
         the browsing by Mediatypes in the search interface. 
    -->
    <xsl:for-each select="foxml:datastream">
      <IndexField IFname="ds.id" index="UN_TOKENIZED" store="YES" termVector="NO">
        <xsl:value-of select="@ID"/>
      </IndexField>
      <xsl:if test="@CONTROL_GROUP!='X'">
        <xsl:for-each select="foxml:datastreamVersion[last()]/@*">
          <IndexField index="UN_TOKENIZED" store="YES" termVector="NO">
            <xsl:attribute name="IFname">
              <xsl:value-of select="concat(../../@ID, '.', name())"/>
            </xsl:attribute>
            <xsl:value-of select="."/>
          </IndexField>
        </xsl:for-each>
      </xsl:if>
    </xsl:for-each>


    <!-- Author: ChR Date: 2008-08-11
         This will index the fields of the RELS-EXT datastream. This is needed for
         the browsing by institutions in the search interface. 
    -->
    <IndexField IFname="rels-ext.isMemberOfCollection" index="UN_TOKENIZED" store="YES" termVector="NO">
      <xsl:value-of select="substring-after(foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/rel:isMemberOfCollection/@rdf:resource,'/')"/>
    </IndexField>
    <xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/fedora-model:hasModel">
      <IndexField IFname="fedora-model.hasModel" index="UN_TOKENIZED" store="YES" termVector="NO">
        <xsl:value-of select="substring-after(@rdf:resource,'/')"/>
      </IndexField>
    </xsl:for-each>
    <IndexField IFname="oai.setSpec" index="TOKENIZED" store="YES" termVector="NO">
      <xsl:value-of select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF/rdf:Description/oai:setSpec/text()"/>
    </IndexField>


<!--indexing foxml fields-->
<!--
<xsl:for-each select="//audit:action">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="audit.action" displayName="audit.action">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//audit:componentID">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="audit.componentID" displayName="audit.componentID">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//audit:date">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="audit.date" displayName="audit.date">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//audit:justification">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="audit.justification" displayName="audit.justification">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//audit:process">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="audit.process" displayName="audit.process">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//audit:process/@type">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="audit.process_type" displayName="audit.process_type">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//audit:record/@ID">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="audit.record_ID" displayName="audit.record_ID">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//audit:responsibility">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="audit.responsibility" displayName="audit.responsibility">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:creator">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.creator" displayName="dc.creator">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:date">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.date" displayName="dc.date">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:description">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.description" displayName="dc.description">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:format">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.format" displayName="dc.format">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:identifier">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.identifier" displayName="dc.identifier">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:publisher">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.publisher" displayName="dc.publisher">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:relation">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.relation" displayName="dc.relation">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:rights">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.rights" displayName="dc.rights">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:subject">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.subject" displayName="dc.subject">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//dc:title">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="dc.title" displayName="dc.title">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:contentLocation">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="foxml.contentLocation" displayName="foxml.contentLocation">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:contentLocation/@REF">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.contentLocation_REF" displayName="foxml.contentLocation_REF">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:contentLocation/@TYPE">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.contentLocation_TYPE" displayName="foxml.contentLocation_TYPE">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastream/@CONTROL_GROUP">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastream_CONTROL_GROUP" displayName="foxml.datastream_CONTROL_GROUP">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastream/@ID">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastream_ID" displayName="foxml.datastream_ID">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastream/@STATE">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastream_STATE" displayName="foxml.datastream_STATE">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastream/@VERSIONABLE">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastream_VERSIONABLE" displayName="foxml.datastream_VERSIONABLE">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastreamVersion/@CREATED">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastreamVersion_CREATED" displayName="foxml.datastreamVersion_CREATED">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastreamVersion/@FORMAT_URI">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastreamVersion_FORMAT_URI" displayName="foxml.datastreamVersion_FORMAT_URI">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastreamVersion/@ID">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastreamVersion_ID" displayName="foxml.datastreamVersion_ID">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastreamVersion/@LABEL">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastreamVersion_LABEL" displayName="foxml.datastreamVersion_LABEL">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastreamVersion/@MIMETYPE">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastreamVersion_MIMETYPE" displayName="foxml.datastreamVersion_MIMETYPE">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:datastreamVersion/@SIZE">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.datastreamVersion_SIZE" displayName="foxml.datastreamVersion_SIZE">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:digitalObject/@PID">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.digitalObject_PID" displayName="foxml.digitalObject_PID">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:digitalObject/@VERSION">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.digitalObject_VERSION" displayName="foxml.digitalObject_VERSION">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:digitalObject/@xsi:schemaLocation">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.digitalObject_xsi:schemaLocation" displayName="foxml.digitalObject_xsi:schemaLocation">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:property">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="foxml.property" displayName="foxml.property">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:property/@NAME">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.property_NAME" displayName="foxml.property_NAME">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//foxml:property/@VALUE">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="foxml.property_VALUE" displayName="foxml.property_VALUE">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//meta:creator">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="meta.creator" displayName="meta.creator">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//meta:description">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="meta.description" displayName="meta.description">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//meta:publisher">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="meta.publisher" displayName="meta.publisher">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//meta:subject">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="meta.subject" displayName="meta.subject">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//meta:title">
<IndexField index="TOKENIZED" store="YES" termVector="YES" boost="1.0" IFname="meta.title" displayName="meta.title">
<xsl:value-of select="text()"/>
</IndexField>
</xsl:for-each>
<xsl:for-each select="//oai_dc:dc/@xsi:schemaLocation">
<IndexField index="UN_TOKENIZED" store="YES" termVector="NO" boost="1.0" IFname="oai_dc.dc_xsi:schemaLocation" displayName="oai_dc.dc_xsi:schemaLocation">
<xsl:value-of select="."/>
</IndexField>
</xsl:for-each>
-->
<!-- a datastream is fetched, if its mimetype 
			     can be handled, the text becomes the value of the field. 
			     This is the version using PDFBox,
			     below is the new version using Apache Tika. -->
<!---->
<!-- Text and metadata extraction using Apache Tika. -->
<xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M' or @CONTROL_GROUP='E' or @CONTROL_GROUP='R']">
<xsl:value-of disable-output-escaping="yes" select="exts:getDatastreamFromTika($PID, $REPOSITORYNAME, @ID, 'IndexField', concat('ds.', @ID), concat('dsmd.', @ID, '.'), '', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
</xsl:for-each>
<!--creating an index field with all text from the foxml record and its datastreams-->
<IndexField IFname="foxml.all.text" index="TOKENIZED" store="YES" termVector="YES">
<xsl:for-each select="//text()">
<xsl:value-of select="."/>
<xsl:text> </xsl:text>
</xsl:for-each>
<xsl:for-each select="//foxml:datastream[@CONTROL_GROUP='M' or @CONTROL_GROUP='E' or @CONTROL_GROUP='R']">
<xsl:value-of select="exts:getDatastreamText($PID, $REPOSITORYNAME, @ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
<xsl:text> </xsl:text>
</xsl:for-each>
</IndexField>
</xsl:template>
</xsl:stylesheet>
