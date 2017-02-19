### 1.2 / 2016-02-19

*   1 minor enhancement

    *   cartage-bundler now adds Cartage#run_without_bundler as a convenience
        method for dependent plug-ins to use.

### 1.1 / 2016-02-17

*   1 minor enhancement

    *   cartage-bundler now requests the `post_bundle_install` plug-in feature
        after the install is complete, allowing other plug-ins to depend on the
        completion of cartage-bundler in the packaging process.

### 1.0 / 2016-05-31

*   1 major enhancement

    *   Happy Birthday! cartage-bundler has been created as part of the Cartage
        2.0 rewrite and represents the abstraction of bundler packaging as a
        proper plug-in.
