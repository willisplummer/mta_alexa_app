port module Authenticate exposing (..)

import Signup
import Html exposing (div, Html, text, a, button, input)
import Html.App as App
import Html.Attributes exposing (href, type', placeholder, class, style)
import Html.Events exposing (onInput, onClick)
import Http
import API
import Task
import String exposing (isEmpty)
import List exposing (map, concat, concatMap)


type alias Model =
    { signup : Signup.Model
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


init : Maybe ActiveUserCreds -> ( Model, Cmd Msg )
init creds =
    let
        ( signupModel, signupMsgs ) =
            Signup.init
    in
        ( { signup = signupModel
          , login = initialLoginModel
          , activeUser = creds
          }
        , Cmd.map Signup signupMsgs
        )


emptyModel : Model
emptyModel =
    Model Signup.initialModel initialLoginModel Nothing


type Msg
    = Signup Signup.Msg
    | Logout
    | LoginEmail String
    | LoginPassword String
    | LoginValidate
    | LoginFetchSucceed ( Maybe String, Maybe String )
    | LoginFetchFail Http.Error


port setToken : Maybe ActiveUserCreds -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        Signup subMsg ->
            let
                ( signup, signupCmds ) =
                    Signup.update subMsg model.signup

                creds =
                    case signup.token of
                        Just token ->
                            Just { token = token, email = signup.email }

                        Nothing ->
                            Nothing

                response =
                    case subMsg of
                        Signup.FetchSucceed arguments ->
                            ( { model | signup = signup, activeUser = creds }
                            , Cmd.batch
                                [ Cmd.map Signup signupCmds
                                , setToken creds
                                ]
                            )

                        _ ->
                            ( { model | signup = signup }
                            , Cmd.map Signup signupCmds
                            )
            in
                response

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


loginView : Model -> Html Msg
loginView model =
    let
        serverErrors =
            case model.login.errors.server of
                Just error ->
                    [ div [ class "validation-error", style [ ( "color", "red " ) ] ]
                        [ text error ]
                    ]

                Nothing ->
                    []

        body =
            validatedLoginInput [ ( "Email", "text", LoginEmail ) ] model.login.errors.email
                ++ validatedLoginInput [ ( "Password", "password", LoginPassword ) ] model.login.errors.password
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
            div []
                [ App.map Signup (Signup.view model.signup)
                ]

        LoginView ->
            loginView model
