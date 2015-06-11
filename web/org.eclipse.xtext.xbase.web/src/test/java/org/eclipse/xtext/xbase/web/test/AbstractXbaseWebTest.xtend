/*******************************************************************************
 * Copyright (c) 2015 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.xbase.web.test

import com.google.inject.Guice
import com.google.inject.util.Modules
import java.io.File
import java.io.FileWriter
import java.util.HashMap
import java.util.Map
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.eclipse.emf.common.util.URI
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.idea.example.entities.EntitiesRuntimeModule
import org.eclipse.xtext.idea.example.entities.EntitiesStandaloneSetup
import org.eclipse.xtext.junit4.AbstractXtextTests
import org.eclipse.xtext.web.server.ISessionStore
import org.eclipse.xtext.web.server.XtextServiceDispatcher
import org.eclipse.xtext.web.server.persistence.IResourceBaseProvider
import org.eclipse.xtext.xbase.web.test.languages.EntitiesWebModule

@Accessors(PROTECTED_GETTER)
class AbstractXbaseWebTest extends AbstractXtextTests {
	
	static class TestResourceBaseProvider implements IResourceBaseProvider {
		val testFiles = new HashMap<String, URI>
		
		override getFileURI(String resourceId) {
			testFiles.get(resourceId)
		}
	}
	
	ExecutorService executorService
	
	TestResourceBaseProvider resourceBaseProvider
	
	XtextServiceDispatcher dispatcher
	
	protected def getRuntimeModule() {
		new EntitiesRuntimeModule
	}
	
	override void setUp() {
		super.setUp()
		executorService = Executors.newCachedThreadPool
		resourceBaseProvider = new TestResourceBaseProvider
		with(new EntitiesStandaloneSetup {
			override createInjector() {
				val webModule = new EntitiesWebModule(executorService)
				webModule.resourceBaseProvider = resourceBaseProvider
				return Guice.createInjector(Modules.override(runtimeModule).with(webModule))
			}
		})
		dispatcher = injector.getInstance(XtextServiceDispatcher)
	}
	
	override tearDown() {
		executorService.shutdown()
		super.tearDown()
	}
	
	protected def createFile(String content) {
		val file = File.createTempFile('test', '.entities')
		resourceBaseProvider.testFiles.put(file.name, URI.createFileURI(file.absolutePath))
		val writer = new FileWriter(file)
		writer.write(content)
		writer.close()
		file.deleteOnExit
		return file
	}
	
	protected def getService(String path, Map<String, String> parameters) {
		getService(path, parameters, new HashMapSessionStore)
	}
	
	protected def getService(String path, Map<String, String> parameters, ISessionStore sessionStore) {
		val requestData = new MockRequestData(path, parameters)
		dispatcher.getService(requestData, sessionStore)
	}
	
}
