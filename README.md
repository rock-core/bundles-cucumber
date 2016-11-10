= Cucumber/Rock integration for Syskit apps

This bundle implements the basic support to use Cucumber for acceptance testing
in your Syskit apps. This integration assumes that you use Gazebo as your
system's simulator

The rest of this readme will deal with the basic work required to add Cucumber
support to your bundle using this integration

== Initialization

The integration requires some bundle-specific work. The simple bits of this work
is automated, but it is possible that you would need to "tune" it to match your
needs. You may also want to see the [Manual
Installation](#manual-installation) section at the end of the document.

=== Dependencies

The first step is to (manually) add the bundle in your own app's dependency
list, that is:
 - add bundles/cucumber in your own bundle's `manifest.xml`
 - add cucumber to the list of dependencies in your bundles's
   `config/bundle.yml`

=== Automated Way

TBD, Idea:

The automated integration assumes that you have a 'simulation' robot
configuration, and that this configuration has a profile in which the robot's
SDF model is being loaded.

Let's assume that the robot configuration is `gazebo` and that the profile is
`Profiles::Gazebo::Base`, you would run:

    syskit gen cucumber gazebo Profiles::Gazebo::Base

It creates the basic cucumber scaffolding, as well as a `Profiles::Cucumber`
profile and a `cucumber` robot that respectively define the actions required by
the cucumber steps themselves, and add it to the main action interface on top of
your simulated robot's actions.

== Usage

=== Step definitions

The bundle implements a number of Cucumber steps. Generally speaking, the
structure is a Given that defines a robot and gazebo world, and a list of
When/Then where the When starts an action and the Then list monitors (list of
things that should be maintained during the action's lifetime) and finish with a
termination predicate (something that blocks until a condition is met).

For instance:

    # Start the app with the 'cucumber' configuration and moves the robot at the
    # origin in the test_world scene
    Given the cucumber robot starting at origin in the test world
    # Start constant_z_def(setpoint: -10)
    When it runs the constant z definition with setpoint=-10m
    # Block until the condition is met, or fails if that condition is not met
    # within 2 minutes
    Then the pose reaches z=-10m with a tolerance of 1m within 2min
    # Start constant_yaw_def(setpoint: 15 * Math::PI / 180) in addition to constant_z_def
    When it runs the constant yaw definition with setpoint=15deg
    # Monitor that the pose is within constraints while the action runs
    Then the pose is maintained at z=-10m with a tolerance of 1m
    # Block until the condition is met, or fails if that condition is not met
    # within 2 minutes. Will fail if the monitor started above fails.
    # Both monitors are dropped when this condition finishes
    And the pose reaches yaw=15deg with a tolerance of 2deg within 2min

=== Running the steps

One runs the steps the normal cucumber way

    cucumber

or

    cucumber features/feature_file.features

=== Validating the steps

A special validation mode can be used to validate the action names and the list
of action arguments. Call the cucumber features with the `ROBY_VALIDATE_STEPS`
envvar set to 1:

    cucumber ROBY_VALIDATE_STEPS=1 features/feature_file.features

The actions will not be executed, only the action names will be validated, as
well as the fact that the action arguments match the expected arguments.

== Manual Installation

Adding cucumber to a bundle requires a number of steps (in addition to adding
the dependencies as described above). The best way is probably to run the syskit
generator, and fine-tune the result. If that's not acceptable to you, what
follows basically describes what the generator does.

 - run 'cucumber init' in your bundle
 - edit `features/support/env.rb` and add the Roby, RockGazebo and this bundle's
   own World modules to the Cucumber world.

   ```
   require 'rock/bundles'
   Bundles.setup_search_paths
   require 'cucumber/rock_world'
   Cucumber::RockWorld.setup
   World(Roby::App::Cucumber::World,
         RockGazebo::Syskit::Cucumber::World,
         Cucumber::RockWorld)
   ```

 - the cucumber steps require a set of actions that must be provided by the
   bundle-under-test. This bundle describes them in
   `Cucumber::Actions::Cucumber`, but these actions are not self-contained (one
   needs to provide the robot's pose and allow to change the robot pose).

   Your bundle therefore needs to overload this action interface and inject the
   robot model from gazebo. Then, it needs to provide a robot configuration in
   which the action interface is loaded (usually called 'cucumber')

