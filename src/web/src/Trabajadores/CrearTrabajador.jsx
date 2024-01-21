import {  Image, Platform, Pressable , StyleSheet, Text, View} from 'react-native'
import { Switch, TextInput } from 'react-native-paper';
import axios from 'axios';
import { useNavigate } from 'react-router-native';
import {useState} from 'react'

const useHost = () => {
    if (Platform.OS === 'android') {
      return 'http://10.0.2.2:5050/trabajadores';
    } else {
      return 'http://localhost:5050/trabajadores';
    }
};

const CrearTrabajador = ()=>{
    const navigate = useNavigate(); 
        const handleButtonClick = (enlace) => {
        
        navigate(enlace);
    };

    const [nombre, setNombre] = useState('');
    const [libre, setLibre] = useState(false);
    const [id, setId] = useState('');
    const [turno, setTurno]=useState('');



    const toggleLibre = () => {
        setLibre(!libre);
    };

    const handleCreateTrabajador = () => {
        // Realiza una solicitud POST al servidor backend para crear un alumno
        axios.post(`${useHost()}/creartrabajador`, {
           id, 
           nombre,
           turno, 
           libre
        })
        .then((response) => {
            // Maneja la respuesta exitosa
            navigate('/trabajadores');
        })
        .catch((error) => {
            // Maneja los errores
            navigate('/confirmaciones', { state: { mensaje: 'Error en la creación del trabajador',error } });
        });
        
    };

    return(
        <View>
            <View style={styles.container}>
                <View style={styles.header}>
                    <Image style={styles.image} source={require('../../LogoMcAndCheese.png')} />
                    <Text style={styles.title}>McAndCheese - Práctica 3</Text>
                </View>
            </View>
            <Text style={styles.titleText}>Subsistema de Trabajadores</Text>
            <Text style={styles.titleText}>Crear un Nuevo Trabajador</Text>
            
            <Text style={styles.text}>DNI (ID del trabajador):</Text>
            <TextInput style={styles.textInput}
                label="DNI"
                value={id}
                onChangeText={text => setId(text)}
            />
            <Text style={styles.text}>Nombre y apellidos:</Text>
            <TextInput style={styles.textInput}
                label="Nombre"
                value={nombre}
                onChangeText={text => setNombre(text)}
            />
            <Text style={styles.text}>Introduzca el turno de trabajo (nº de horas): </Text>
            <TextInput style={styles.textInput}
            label="Turno de trabajo"
            value={turno}
            onChangeText={text => setTurno(text)}
            />
            <Text style={styles.text}>¿Se encuentra trabajando actualmente? </Text>
            <Switch style={styles.switch}
                value={libre}
                onValueChange={toggleLibre}
                trackColor={{false: 'grey', true: 'blue'}}
                thumbColor={libre ? '#f5dd4b' : '#f4f3f4'}
            />

            <View style={styles.button}>
                <Pressable style={styles.pressableButton} onPress={handleCreateTrabajador}>
                    <Text style={styles.pressableText}>Crear Trabajador</Text>
                </Pressable> 
            </View>

            <View style={styles.button}>
                <Pressable style={styles.pressableButton} onPress={() => handleButtonClick('/trabajadores')}>
                    <Text style={styles.pressableText}>Volver atrás</Text>
                </Pressable> 
            </View>
            
        </View>
        
    )

};

const styles = StyleSheet.create({
  image: {
    width: 200, // Ajusta el ancho según tus necesidades
    height: 200, // Ajusta la altura según tus necesidades
    borderRadius: 0,
    marginBottom: 20,
  },
text:{
    flex: 1,
    justifyContent: 'center', // Centra horizontalmente
    textAlign: 'center', 
    fontSize: 15,
    marginTop: 10,
    marginBottom: 10,
    fontWeight: 'bold'
},
titleText:{
    flex: 1,
    justifyContent: 'center', // Centra horizontalmente
    textAlign: 'center', 
    fontSize: 20,
    marginTop: 10,
    marginBottom: 10,
    fontWeight: 'bold'
},
textInput:{
    borderRadius: 5,
    borderWidth: 1,
    borderColor: '#999',
    paddingHorizontal: 20,
    paddingVertical: 10,
    marginTop: 5,
    marginBottom: 5,
    width: 500,
    justifyContent: 'center',
    alignSelf: 'center',
},
mensajeError: {
    fontSize: 16,
    color: 'red', // Puedes cambiar el color a tu preferencia
    textAlign: 'center',
    marginTop: 10,
},mensajeExito: {
    fontSize: 16,
    color: 'black', // Puedes cambiar el color a tu preferencia
    textAlign: 'center',
    marginTop: 10,
},
pressableButton: {
    width: 200,
    height: 50,
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center',
    backgroundColor: '#049CDC',  // Un verde fresco, puedes cambiarlo según tus preferencias
    borderRadius: 10,
    elevation: 3, // Sombra para un efecto de elevación
    marginBottom: 15,
    marginTop: 15,
    paddingHorizontal: 20,
    paddingVertical: 10,
},
headerText: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    color: '#333',  // Un tono de gris oscuro, puedes ajustarlo según tus preferencias
    marginTop: 20,
    marginBottom: 10,
},
pressableText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold', // Texto en negrita
    textAlign: 'center',
},  
header: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center'
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    marginLeft: 20,
  },
    switch:{
        alignSelf: 'center'
    },
    titleText:{
        flex: 1,
        justifyContent: 'center', // Centra horizontalmente
        textAlign: 'center', 
        fontSize: 20,
        marginTop: 10,
        marginBottom: 10,
        fontWeight: 'bold'
    },
    fabStyle: {
      width: 55,
     backgroundColor: '#049CDC',
     alignSelf: 'right',
     justifyContent: 'center',
   }
});

export default CrearTrabajador;