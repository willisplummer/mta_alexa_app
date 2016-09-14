port module Main exposing (..)

import Html exposing (div, Html, text, a, button, input)
import Html.Attributes exposing (href, type', placeholder, class, style)
import Html.Events exposing (onInput, onClick)
import Http
import API
import Task
import String exposing (isEmpty)
import List exposing (map, concat, concatMap)
import Navigation
import LoggedIn
import API
import Routing exposing (..)
import Html.App as App


--


main : Program ( Maybe String, Maybe String )
main =
    Navigation.programWithFlags Routing.parser
        { init = init
        , subscriptions = subscriptions
        , view = view
        , urlUpdate = urlUpdate
        , update = update
        }


init : ( Maybe String, Maybe String ) -> Result String Route -> ( Model, Cmd Msg )
init ( token, email ) result =
    let
        ( loggedIn, loggedInMsgs ) =
            LoggedIn.init

        creds =
            case ( token, email ) of
                ( Just token, Just email ) ->
                    Just (ActiveUserCreds token email)

                _ ->
                    Nothing

        initialAuthenticateModel =
            { signup = initialSignupModel
            , login = initialLoginModel
            , activeUser = creds
            }

        currentRoute =
            routeFromResult result
    in
        ( { authenticate = initialAuthenticateModel, loggedIn = loggedIn, route = currentRoute }
        , Cmd.map LoggedIn loggedInMsgs
        )


urlUpdate : Result String Route -> Model -> ( Model, Cmd Msg )
urlUpdate result model =
    let
        currentRoute =
            Routing.routeFromResult result

        authenticated =
            case model.authenticate.activeUser of
                Just user ->
                    True

                Nothing ->
                    False

        newRoute =
            if authenticated then
                case currentRoute of
                    SignupRoute ->
                        HomeRoute

                    LoginRoute ->
                        HomeRoute

                    _ ->
                        currentRoute
            else
                case currentRoute of
                    HomeRoute ->
                        LoginRoute

                    _ ->
                        currentRoute

        commands =
            if newRoute == currentRoute then
                Cmd.none
            else
                (Routing.updateUrl newRoute)
    in
        ( { model | route = newRoute }, commands )



-- MODEL


type alias Model =
    { authenticate : AuthenticateModel
    , loggedIn : LoggedIn.Model
    , route : Routing.Route
    }


type Page
    = SignUpPage
    | LoginPage
    | HomePage



--


type alias AuthenticateModel =
    { signup : SignupModel
    , login : LoginModel
    , activeUser : Maybe ActiveUserCreds
    }


type AuthenticateDisplay
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


emptyAuthenticateModel : AuthenticateModel
emptyAuthenticateModel =
    AuthenticateModel initialSignupModel initialLoginModel Nothing


type Msg
    = Logout
    | LoggedIn LoggedIn.Msg
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
        LoggedIn subMsg ->
            case subMsg of
                LoggedIn.Logout ->
                    ( { model
                        | loggedIn = LoggedIn.emptyModel
                        , authenticate = emptyAuthenticateModel
                        , route = LoginRoute
                      }
                    , Cmd.batch
                        [ setToken Nothing
                        , Routing.updateUrl HomeRoute
                        ]
                    )

                _ ->
                    let
                        ( loggedIn, loggedInCmds ) =
                            LoggedIn.update subMsg model.loggedIn
                    in
                        ( { model | loggedIn = loggedIn }
                        , Cmd.map LoggedIn loggedInCmds
                        )

        LoginEmail email ->
            let
                oldLogin =
                    model.authenticate.login

                newLogin =
                    { oldLogin | email = email }

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | login = newLogin }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        LoginPassword password ->
            let
                oldLogin =
                    model.authenticate.login

                newLogin =
                    { oldLogin | password = password }

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | login = newLogin }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        LoginValidate ->
            let
                newLogin =
                    validateLogin model.authenticate.login

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | login = newLogin }

                newModel =
                    { model | authenticate = newAuthenticate }

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
                    model.authenticate.login

                newLogin =
                    { oldLogin | errors = LoginErrors Nothing Nothing errors }

                activeUserResponse =
                    case token of
                        Just token ->
                            Just { token = token, email = newLogin.email }

                        Nothing ->
                            Nothing

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | login = newLogin, activeUser = activeUserResponse }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        LoginFetchFail token ->
            let
                oldLogin =
                    model.authenticate.login

                newLogin =
                    { oldLogin | errors = LoginErrors Nothing Nothing (Just "there was a problem connecting to the server. please try again.") }

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | login = newLogin, activeUser = Nothing }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        SignupEmail email ->
            let
                oldSignup =
                    model.authenticate.signup

                newSignup =
                    { oldSignup | email = email }

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | signup = newSignup }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        SignupPassword password ->
            let
                oldSignup =
                    model.authenticate.signup

                newSignup =
                    { oldSignup | password = password }

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | signup = newSignup }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        SignupPasswordAgain passwordAgain ->
            let
                oldSignup =
                    model.authenticate.signup

                newSignup =
                    { oldSignup | passwordAgain = passwordAgain }

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | signup = newSignup }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        SignupValidate ->
            let
                newSignup =
                    validateSignup model.authenticate.signup

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | signup = newSignup }

                newModel =
                    { model | authenticate = newAuthenticate }

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
                    model.authenticate.signup

                newSignup =
                    { oldSignup | errors = SignupErrors Nothing Nothing errors }

                activeUserResponse =
                    case token of
                        Just token ->
                            Just { token = token, email = newSignup.email }

                        Nothing ->
                            Nothing

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | signup = newSignup }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        SignupFetchFail token ->
            let
                oldSignup =
                    model.authenticate.signup

                newSignup =
                    { oldSignup | errors = SignupErrors Nothing Nothing [ "there was a problem connecting to the server. please try again." ] }

                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | signup = newSignup }
            in
                ( { model
                    | authenticate = newAuthenticate
                  }
                , Cmd.none
                )

        Logout ->
            let
                oldAuthenticate =
                    model.authenticate

                newAuthenticate =
                    { oldAuthenticate | activeUser = Nothing }
            in
                ( { model | authenticate = newAuthenticate }
                , setToken model.authenticate.activeUser
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


authenticateView : Model -> AuthenticateDisplay -> Html Msg
authenticateView model view =
    case view of
        SignupView ->
            signupView model.authenticate.signup

        LoginView ->
            loginView model.authenticate.login


view : Model -> Html Msg
view model =
    case model.route of
        LoginRoute ->
            authenticateView model LoginView

        SignupRoute ->
            authenticateView model SignupView

        HomeRoute ->
            App.map
                (\msg -> LoggedIn msg)
                (LoggedIn.view model.loggedIn)

        NotFoundRoute ->
            div [] [ text "NOT FOUND" ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
