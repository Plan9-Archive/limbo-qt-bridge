QtWidgets: module
{
    PATH: con "/dis/lib/qtwidgets.dis";

    Widget: adt {
        name: string;

        init: fn(class, name: string, args: list of string): ref Widget;
        call: fn(w: self ref Widget, method: string, args: list of string): string;
    };

    init: fn();
};
