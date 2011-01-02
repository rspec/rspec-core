## rspec-mocks release history (incomplete)

### 2.4.0 / 2011-01-02

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.3.0...v2.4.0)

No functional changes in this release, which was made to align with the
rspec-core-2.4.0 release.

### 2.3.0 / 2010-12-12

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.2.0...v2.3.0)

* Bug fixes 
  * Fix our Marshal extension so that it does not interfere with objects that
    have their own @mock_proxy instance variable. (Myron Marston)

### 2.2.0 / 2010-11-28

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.1.0...v2.2.0)

* Enhancements
  * Added "rspec/mocks/standalone" for exploring the rspec-mocks in irb.

* Bug fix
  * Eliminate warning on splat args without parens (Gioele Barabucci)
  * Fix bug where obj.should_receive(:foo).with(stub.as_null_object) would                                                                                                      
    pass with a false positive.

### 2.1.0 / 2010-11-07

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.0.1...v2.1.0)

* Bug fixes
  * Fix serialization of stubbed object (Josep M Bach)

### 2.0.0 / 2010-10-10

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.0.0.beta.22...v2.0.0)

### 2.0.0.rc / 2010-10-05

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.0.0.beta.22...v2.0.0.rc)

* Enhancements
  * support passing a block to an expecttation block (Nicolas Braem)
    * obj.should_receive(:msg) {|&block| ... }

* Bug fixes
  * Fix YAML serialization of stub (Myron Marston)
  * Fix rdoc rake task (Hans de Graaff)

### 2.0.0.beta.22 / 2010-09-12

[full changelog](http://github.com/rspec/rspec-mocks/compare/v2.0.0.beta.20...v2.0.0.beta.22)

* Bug fixes
  * fixed regression that broke obj.stub_chain(:a, :b => :c)
  * fixed regression that broke obj.stub_chain(:a, :b) { :c }
  * respond_to? always returns true when using as_null_object
