module Stop exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)


main =
    App.program
        { init = ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { mtaStopId : String
    , name : String
    , default : Bool
    , view : View
    }


initialModel : Model
initialModel =
    { mtaStopId = ""
    , name = ""
    , default = False
    , view = Edit
    }



--


type Msg
    = Name String
    | MtaStopId String
    | Default Bool
    | ChangeView View
    | Remove


type View
    = Edit
    | Show


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Name name ->
            ( { model | name = name }
            , Cmd.none
            )

        MtaStopId mtaStopId ->
            ( { model | mtaStopId = mtaStopId }
            , Cmd.none
            )

        Default bool ->
            ( { model | default = bool }
            , Cmd.none
            )

        ChangeView view ->
            ( { model | view = view }
            , Cmd.none
            )

        Remove ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model.view of
        Show ->
            showStopView model

        Edit ->
            editStopView model


displayDefaultHelper : Model -> String
displayDefaultHelper model =
    if model.default then
        " (Default)"
    else
        ""


showStopView : Model -> Html Msg
showStopView model =
    div []
        [ div [] [ text (model.name ++ " (" ++ model.mtaStopId ++ ")" ++ (displayDefaultHelper model)) ]
        , input [ type' "checkbox", checked model.default, onCheck Default ] [ text "default?" ]
        , button [ onClick (ChangeView Edit) ] [ text "Edit" ]
        , button [ onClick Remove ] [ text "remove" ]
        ]


editStopView : Model -> Html Msg
editStopView model =
    div []
        [ input [ type' "text", placeholder "MTA STOP ID", value model.mtaStopId, onInput MtaStopId ] []
        , br [] []
        , input [ type' "text", placeholder "Stop Nickname", value model.name, onInput Name ] []
        , br [] []
        , button [ onClick (ChangeView Show) ] [ text "Submit" ]
        ]



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
