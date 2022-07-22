export default class Type{
    private _id: number;
    private _name: string;
    private _author: string;
    private _year: number;

    constructor(id: number, name: string, author: string, year: number){
        this._id = id;
        this._name = name;
        this._author = author;
        this._year = year;
    }

    get id(): number{
        return this._id;
    }

    get name(): string{
        return this._name;
    }

    get author(): string{
        return this._author;
    }

    get year(): number{
        return this._year;
    }
}