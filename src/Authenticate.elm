port module Authenticate exposing (..)

import Html exposing (div, Html, text, a, button, input)
import Html.Attributes exposing (href, type', placeholder, class, style)
import Html.Events exposing (onInput, onClick)
import Http
import API
import Task
import String exposing (isEmpty)
import List exposing (map, concat, concatMap)


type alias Model =
    { signup : SignupModel
    , login : LoginModel
    , activeUser : Maybe ActiveUserCreds
    }


type Display
    = SignupView
    | LoginView


type alias ActiveUserCreds =
    { token : String
    , email : String
    }


type alias LoginModel =
    { email : String
    , password : String
    , errors : LoginErrors
    }


type alias LoginErrors =
    { email : Maybe String
    , password : Maybe String
    , server : Maybe String
    }


initialLoginErrors : LoginErrors
initialLoginErrors =
    LoginErrors Nothing Nothing Nothing


initialLoginModel : LoginModel
initialLoginModel =
    LoginModel "" "" initialLoginErrors


type alias SignupModel =
    { email : String
    , password : String
    , passwordAgain : String
    , errors : SignupErrors
    }


type alias SignupErrors =
    { email : Maybe String
    , password : Maybe String
    , server : List String
    }


initialSignupErrors : SignupErrors
initialSignupErrors =
    SignupErrors Nothing Nothing []


initialSignupModel : SignupModel
initialSignupModel =
    SignupModel "" "" "" initialSignupErrors


init : Maybe ActiveUserCreds -> ( Model, Cmd Msg )
init creds =
    ( { signup = initialSignupModel
      , login = initialLoginModel
      , activeUser = creds
      }
    , Cmd.none
    )


emptyModel : Model
emptyModel =
    Model initialSignupModel initialLoginModel Nothing


type Msg
    = Logout
    | LoginEmail String
    | LoginPassword String
    | LoginValidate
    | LoginFetchSucceed ( Maybe String, Maybe String )
    | LoginFetchFail Http.Error
    | SignupEmail String
    | SignupPassword String
    | SignupPasswordAgain String
    | SignupValidate
    | SignupFetchSucceed ( Maybe String, List String )
    | SignupFetchFail Http.Error


port setToken : Maybe ActiveUserCreds -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        LoginEmail email ->
            let
                oldLogin =
                    model.login

                newLogin =
                    { oldLogin | email = email }
            in
                ( { model
                    | login = newLogin
                  }
                , Cmd.none
                )

        LoginPassword password ->
            let
                oldLogin =
                    model.login

                newLogin =
                    { oldLogin | password = password }
            in
                ( { model
                    | login = newLogin
                  }
                , Cmd.none
                )

        LoginValidate ->
            let
                newLogin =
                    validateLogin model.login

                newModel =
                    { model | login = newLogin }

                cmd =
                    if loginIsValid newLogin then
                        Task.perform LoginFetchFail LoginFetchSucceed (API.submitLoginData ( newLogin.email, newLogin.password ))
                    else
                        Cmd.none
            in
                ( newModel
                , cmd
                )

        LoginFetchSucceed ( token, errors ) ->
            let
                oldLogin =
                    model.login

                newLogin =
                    { oldLogin | errors = LoginErrors Nothing Nothing errors }

                activeUserResponse =
                    case token of
                        Just token ->
                            Just { token = token, email = newLogin.email }

                        Nothing ->
                            Nothing
            in
                ( { model
                    | activeUser = activeUserResponse
                    , login = newLogin
                  }
                , Cmd.none
                )

        LoginFetchFail token ->
            let
                oldLogin =
                    model.login

                newLogin =
                    { oldLogin | errors = LoginErrors Nothing Nothing (Just "there was a problem connecting to the server. please try again.") }
            in
                ( { model
                    | activeUser = Nothing
                    , login = newLogin
                  }
                , Cmd.none
                )

        SignupEmail email ->
            let
                oldSignup =
                    model.signup

                newSignup =
                    { oldSignup | email = email }
            in
                ( { model
                    | signup = newSignup
                  }
                , Cmd.none
                )

        SignupPassword password ->
            let
                oldSignup =
                    model.signup

                newSignup =
                    { oldSignup | password = password }
            in
                ( { model
                    | signup = newSignup
                  }
                , Cmd.none
                )

        SignupPasswordAgain passwordAgain ->
            let
                oldSignup =
                    model.signup

                newSignup =
                    { oldSignup | passwordAgain = passwordAgain }
            in
                ( { model
                    | signup = newSignup
                  }
                , Cmd.none
                )

        SignupValidate ->
            let
                newSignup =
                    validateSignup model.signup

                newModel =
                    { model | signup = newSignup }

                cmd =
                    if signupIsValid newSignup then
                        Task.perform SignupFetchFail SignupFetchSucceed (API.submitSignupData ( newSignup.email, newSignup.password, newSignup.passwordAgain ))
                    else
                        Cmd.none
            in
                ( newModel
                , cmd
                )

        SignupFetchSucceed ( token, errors ) ->
            let
                oldSignup =
                    model.signup

                newSignup =
                    { oldSignup | errors = SignupErrors Nothing Nothing errors }

                activeUserResponse =
                    case token of
                        Just token ->
                            Just { token = token, email = newSignup.email }

                        Nothing ->
                            Nothing
            in
                ( { model
                    | activeUser = activeUserResponse
                    , signup = newSignup
                  }
                , Cmd.none
                )

        SignupFetchFail token ->
            let
                oldSignup =
                    model.signup

                newSignup =
                    { oldSignup | errors = SignupErrors Nothing Nothing [ "there was a problem connecting to the server. please try again." ] }
            in
                ( { model
                    | activeUser = Nothing
                    , signup = newSignup
                  }
                , Cmd.none
                )

        Logout ->
            ( { model | activeUser = Nothing }
            , setToken model.activeUser
            )


logout : Model -> ( Model, Cmd Msg )
logout model =
    update Logout model


validateLogin : LoginModel -> LoginModel
validateLogin login =
    let
        newErrors =
            { email =
                if isEmpty login.email then
                    Just "Enter an email address"
                    -- TO DO: Validate email format
                else
                    Nothing
            , password =
                if isEmpty login.password then
                    Just "Enter your password!"
                else
                    Nothing
            , server =
                Nothing
            }
    in
        { login | errors = newErrors }


loginIsValid : LoginModel -> Bool
loginIsValid login =
    login.errors.email == Nothing && login.errors.password == Nothing



-- VIEW


validateSignup : SignupModel -> SignupModel
validateSignup model =
    let
        newErrors =
            { email =
                if isEmpty model.email then
                    Just "Enter an email address!"
                    -- TO DO: Validate email format
                else
                    Nothing
            , password =
                if isEmpty model.password then
                    Just "Enter a password!"
                else if isEmpty model.passwordAgain then
                    Just "Please re-enter your password!"
                else if model.password /= model.passwordAgain then
                    Just "Passwords don't match"
                else
                    Nothing
            , server =
                []
            }
    in
        { model | errors = newErrors }


signupIsValid : SignupModel -> Bool
signupIsValid signupModel =
    signupModel.errors.email == Nothing && signupModel.errors.password == Nothing



-- VIEW


signupView : SignupModel -> Html Msg
signupView model =
    let
        serverErrors =
            if List.isEmpty model.errors.server then
                []
            else
                [ div [ class "validation-error", style [ ( "color", "red " ) ] ]
                    (List.map (\str -> text str) model.errors.server)
                ]

        body =
            validatedSignupInput [ ( "Email", "text", SignupEmail ) ] model.errors.email
                ++ validatedSignupInput [ ( "Password", "password", SignupPassword ), ( "Re-enter Password", "password", SignupPasswordAgain ) ] model.errors.password
                ++ [ button [ onClick SignupValidate ] [ text "Submit" ]
                   ]
                ++ serverErrors
                ++ [ div []
                        [ text "already have an account? you can always just "
                        , a [ href "#login" ] [ text "login" ]
                        ]
                   ]
    in
        div [] body


validatedSignupInput : List ( String, String, String -> Msg ) -> Maybe String -> List (Html Msg)
validatedSignupInput list error =
    let
        inputFields =
            concatMap (\( a, b, c ) -> [ input [ type' b, placeholder a, onInput c ] [] ]) list

        errorFields =
            case error of
                Just msg ->
                    [ div [ class "validation-error", style [ ( "color", "red" ) ] ] [ text msg ] ]

                Nothing ->
                    []
    in
        inputFields ++ errorFields


loginView : LoginModel -> Html Msg
loginView loginModel =
    let
        serverErrors =
            case loginModel.errors.server of
                Just error ->
                    [ div [ class "validation-error", style [ ( "color", "red " ) ] ]
                        [ text error ]
                    ]

                Nothing ->
                    []

        body =
            validatedLoginInput [ ( "Email", "text", LoginEmail ) ] loginModel.errors.email
                ++ validatedLoginInput [ ( "Password", "password", LoginPassword ) ] loginModel.errors.password
                ++ [ button [ onClick LoginValidate ] [ text "Submit" ]
                   ]
                ++ serverErrors
                ++ [ div []
                        [ text "want to create an account? you can always just "
                        , a [ href "#signup" ] [ text "signup" ]
                        ]
                   ]
    in
        div [] body


validatedLoginInput : List ( String, String, String -> Msg ) -> Maybe String -> List (Html Msg)
validatedLoginInput list error =
    let
        inputFields =
            concatMap (\( a, b, c ) -> [ input [ type' b, placeholder a, onInput c ] [] ]) list

        errorFields =
            case error of
                Just msg ->
                    [ div [ class "validation-error", style [ ( "color", "red" ) ] ] [ text msg ] ]

                Nothing ->
                    []
    in
        inputFields ++ errorFields


view : Model -> Display -> Html Msg
view model view =
    case view of
        SignupView ->
            signupView model.signup

        LoginView ->
            loginView model.login
