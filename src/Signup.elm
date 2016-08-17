module Signup exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Json
import Task
import String exposing (isEmpty)
import List exposing (map, concat, concatMap)


--import Routes
-- MODEL


type alias Model =
    { email : String
    , password : String
    , passwordAgain : String
    , response : String
    , errors : Errors
    }


type alias Errors =
    { email : Maybe String
    , password : Maybe String
    }


initialErrors : Errors
initialErrors =
    Errors Nothing Nothing


model : Model
model =
    Model "" "" "" "" initialErrors


init : Model
init =
    model



-- UPDATE


type Msg
    = Email String
    | Password String
    | PasswordAgain String
    | Validate
    | SuccessToMessage String
    | FailureToMessage Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Email email ->
            ( { model
                | email = email
              }
            , Cmd.none
            )

        Password password ->
            ( { model
                | password = password
              }
            , Cmd.none
            )

        PasswordAgain passwordAgain ->
            ( { model
                | passwordAgain = passwordAgain
              }
            , Cmd.none
            )

        Validate ->
            let
                newModel =
                    validate model

                cmd =
                    if isValid newModel then
                        submitData newModel
                    else
                        Cmd.none
            in
                ( newModel
                , cmd
                )

        SuccessToMessage response ->
            ( { model
                | response = response
              }
            , Cmd.none
            )

        FailureToMessage response ->
            ( { model
                | response = "ERROR!"
              }
            , Cmd.none
            )


validate : Model -> Model
validate model =
    let
        newErrors =
            { email =
                if isEmpty model.email then
                    Just "Enter an email address"
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
            }
    in
        { model | errors = newErrors }


isValid : Model -> Bool
isValid model =
    model.errors.email == Nothing && model.errors.password == Nothing



-- HTTP


submitData : Model -> Cmd Msg
submitData model =
    let
        url =
            "http://jsonplaceholder.typicode.com/users/1"
    in
        Task.perform FailureToMessage SuccessToMessage (Http.get decodeResponse url)


decodeResponse : Json.Decoder String
decodeResponse =
    Json.at [ "email" ] Json.string



-- VIEW


view : Model -> Html Msg
view model =
    let
        body =
            validatedInput [ ( "Email", "text", Email ) ] model.errors.email
                ++ validatedInput [ ( "Password", "password", Password ), ( "Re-enter Password", "password", PasswordAgain ) ] model.errors.password
                ++ [ button [ onClick Validate ] [ text "Submit" ]
                   , div [ class "response" ] [ text model.response ]
                   ]
    in
        div [] body


validatedInput : List ( String, String, String -> Msg ) -> Maybe String -> List (Html Msg)
validatedInput list error =
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


renderHome : Model -> Html Msg
renderHome model =
    div []
        [ img [ src "http://i.ndtvimg.com/i/2015-07/minion-gabbar_470x471_51437144751.jpg" ] []
        , div [] [ text ("welcome home, " ++ model.email ++ ", it's been a minute.. also your password is " ++ model.password) ]
        ]
