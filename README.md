# MyThirdEar

### App Description

MyThirdEar is a mobile application with the objective of helping musicians transcribe music by providing some analysis tools to be used on an audio sample.

### Main Features

The app will provide the ability to:

- Upload an audio file
- Adjust the speed of the audio
- Adjust pitch of the audio
- Loop sections of the audio
- Perform a RTA (Real time Analysis) of the audio to display frequency data

### Screenshots

<p>
    <img src= "../assets/images/My Library.jpg" width="100"/>
    <img src= "https://user-images.githubusercontent.com/50501047/187281484-7a453bb5-8dec-4dd1-b8a7-02a2a55e0123.jpg" width="100"/>
    <img src = "https://user-images.githubusercontent.com/50501047/187281461-3a7d6d7d-7442-4aca-9609-94f453b0bb2d.jpg" width = "100"/>
</p>

## Development Quickstart

**_Note_**: You will only be able to set up for iOS development if you are running MacOS.

#### (FOR iOS ONLY) Install ruby 3.0 with rvm

Follow instructions under `Installing the stable release version` [here](https://rvm.io/rvm/install#1-download-and-run-the-rvm-installation-script).

### Install Flutter

Follow instructions provided for your OS in the Flutter docs [here](https://flutter.dev/docs/get-started/install).

#### iOS

Follow the iOS development instructions in the Flutter docs [here](https://flutter.dev/docs/get-started/install/macos#ios-setup).

##### Switch into the ios folder and run pod install to get necessary dependencies

cd MyThirdEar/ios
pod install

##### Start the iOS simulator

open -a Simulator

flutter pub get
flutter run

#### Android

Follow the android development instructions to download and set up android studio [here](https://flutter.dev/docs/get-started/install/macos#android-setup).

## Git Development Workflow

**IMPORTANT**: _Before force pushing, force merging, or making any extreme decisions regarding the repository or the master branch, please reach out to one of our teammates. It's better to wait and ensure what you are doing won't harm the repository._

### Clone the repo

Make sure you have your ssh keys set up with GitHub, instructions [here](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh).

    git clone git@github.com:znoble360/MyThirdEar.git

### Find an issue to work on

We have a list of issues available [here](https://github.com/znoble360/MyThirdEar/issues) that you can choose from.

**Make sure to:**

1. Assign the issue to yourself.
2. We use GitHub's PM tool "Projects" to track our progress. Drag the card corresponding to the issue into the "In Progress" column [here](https://github.com/znoble360/MyThirdEar/projects/1).
3. Most of these don't have a description, so please add one once you have a plan for development.

### Creating a branch

##### Always branch from latest `master`:

- To check if you're in the `master` branch, run `git branch` and you should get the following output:

  ```
  > git branch
      * master
  ```

- Get the latest changes by running

  `git pull`

##### Naming your branch:

    github_username/issue_number/issue_name

For example for issue 1 with name "_View music player UI_":

    gdijkhoffz/1/music_player_ui

To create the branch just run:

    git checkout -b <new_branch_name>

### Opening a Pull Request

- Once you are ready to submit your code for review you can push the changes from the local version of your branch to the remote version. The first time you run `git push ` from your branch, GitHub will tell you that you need to set up a remote version of your branch by running:

        git push --set-upstream origin <branch_name>

- After pushing your branch, you can follow [these instructions](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) to open a Pull Request.

### Code Review

In order to maintain a stable `master` branch, at least one person from the team must approve your Pull Request before your changes can be merged into `master`.

#### How to perform a Code Review

- Checkout the feature branch related to the PR and try out the person's changes.
- Check the code diff to see the actual line-by-line code changes and add comments if necessary.
- _To learn more about how to conduct a code review and the best practices read [Google's Engineering Practices documentation](https://google.github.io/eng-practices/review/reviewer/)._

#### Merging the changes

- Once a team member reviews your code and approves your PR, you will be able to merge in your changes into the `master` branch using the GitHub UI.
