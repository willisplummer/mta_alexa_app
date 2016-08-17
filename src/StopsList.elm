module StopsList exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Events exposing (..)
import List
import Stop


main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { stops : List IndexedStop
    , uid : Int
    }


type alias IndexedStop =
    { id : Int
    , model : Stop.Model
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


initialModel : Model
initialModel =
    { stops = []
    , uid = 0
    }


type Msg
    = Add
    | Modify Int Stop.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message ({ stops, uid } as model) =
    case message of
        Add ->
            ( { model
                | stops = stops ++ [ IndexedStop uid Stop.initialModel ]
                , uid = uid + 1
              }
            , Cmd.none
            )

        Modify id msg ->
            if msg == Stop.Remove then
                ( { model | stops = List.filter (\t -> t.id /= id) stops }
                , Cmd.none
                )
            else
                ( { model | stops = List.map (updateHelp id msg) stops }
                , Cmd.none
                )


updateHelp : Int -> Stop.Msg -> IndexedStop -> IndexedStop
updateHelp targetId msg { id, model } =
    IndexedStop id
        (if targetId == id then
            fst (Stop.update msg model)
         else
            model
        )


view : Model -> Html Msg
view model =
    let
        stops =
            List.map viewIndexedStop model.stops

        add =
            button [ onClick Add ] [ text "Add a new stop" ]
    in
        div []
            (stops ++ [ add ])


viewIndexedStop : IndexedStop -> Html Msg
viewIndexedStop { id, model } =
    App.map (Modify id) (Stop.view model)



--


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
